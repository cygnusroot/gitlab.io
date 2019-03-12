require 'spec_helper'

describe Gitlab::Geo::HealthCheck, :geo do
  set(:secondary) { create(:geo_node) }

  subject { described_class.new }

  describe '#perform_checks' do
    before do
      allow(Gitlab::Geo).to receive(:current_node).and_return(secondary)
    end

    context 'when an exception is raised' do
      it 'catches the exception nicely and returns the message' do
        allow(Gitlab::Database).to receive(:postgresql?).and_raise('Uh oh')

        expect(subject.perform_checks).to eq('Uh oh')
      end
    end

    context 'without PostgreSQL' do
      it 'raises an error' do
        allow(Gitlab::Database).to receive(:postgresql?) { false }

        expect { subject.perform_checks }.to raise_error(NotImplementedError)
      end
    end

    context 'with PostgreSQL' do
      before do
        allow(Gitlab::Database).to receive(:postgresql?) { true }
      end

      context 'on the primary node' do
        it 'returns an empty string' do
          allow(Gitlab::Geo).to receive(:secondary?) { false }

          expect(subject.perform_checks).to be_blank
        end
      end

      context 'on the secondary node' do
        let(:geo_database_configured) { true }
        let(:db_read_only) { true }

        before do
          allow(Gitlab::Geo).to receive(:secondary?) { true }
          allow(Gitlab::Geo).to receive(:geo_database_configured?) { geo_database_configured }
          allow(Gitlab::Database).to receive(:db_read_only?) { db_read_only }
        end

        context 'when the Geo tracking DB is not configured' do
          let(:geo_database_configured) { false }

          it 'returns an error' do
            expect(subject.perform_checks).to include('Geo database configuration file is missing')
          end
        end

        context 'when the database is writable' do
          let(:db_read_only) { false }

          it 'returns an error' do
            expect(subject.perform_checks).to include('Geo node has a database that is writable which is an indication it is not configured for replication with the primary node.')
          end
        end

        context 'streaming replication' do
          it 'returns an error when replication is not working' do
            allow(Gitlab::Database).to receive(:pg_last_wal_receive_lsn).and_return('pg_last_xlog_receive_location')
            allow(ActiveRecord::Base).to receive_message_chain('connection.execute').with(no_args).with('SELECT * FROM pg_last_xlog_receive_location() as result').and_return(['result' => 'fake'])
            allow(ActiveRecord::Base).to receive_message_chain('connection.select_values').with(no_args).with('SELECT pid FROM pg_stat_wal_receiver').and_return([])

            expect(subject.perform_checks).to match(/Geo node does not appear to be replicating the database from the primary node/)
          end
        end

        context 'archive recovery replication' do
          it 'returns an error when replication is not working' do
            allow(subject).to receive(:streaming_replication_enabled?).and_return(false)
            allow(subject).to receive(:archive_recovery_replication_enabled?).and_return(true)
            allow(Gitlab::Database).to receive(:pg_last_xact_replay_timestamp).and_return('pg_last_xact_replay_timestamp')
            allow(ActiveRecord::Base).to receive_message_chain('connection.execute').with(no_args).with('SELECT * FROM pg_last_xact_replay_timestamp() as result').and_return([{ 'result' => nil }])

            expect(subject.perform_checks).to match(/Geo node does not appear to be replicating the database from the primary node/)
          end
        end

        context 'some sort of replication' do
          before do
            allow(subject).to receive(:replication_enabled?).and_return(true)
          end

          context 'that is not working' do
            it 'returns an error' do
              allow(subject).to receive(:archive_recovery_replication_enabled?).and_return(false)
              allow(subject).to receive(:streaming_replication_enabled?).and_return(false)

              expect(subject.perform_checks).to match(/Geo node does not appear to be replicating the database from the primary node/)
            end
          end

          context 'that is working' do
            before do
              allow(subject).to receive(:replication_working?).and_return(true)
              allow(Gitlab::Geo::Fdw).to receive(:enabled?) { true }
              allow(Gitlab::Geo::Fdw).to receive(:foreign_tables_up_to_date?) { true }
            end

            it 'returns an error if database is not fully migrated' do
              allow(subject).to receive(:database_version).and_return('20170101')
              allow(subject).to receive(:migration_version).and_return('20170201')

              message = subject.perform_checks

              expect(message).to include('Geo database version (20170101) does not match latest migration (20170201)')
              expect(message).to include('gitlab-rake geo:db:migrate')
            end

            it 'returns an error when FDW is disabled' do
              allow(Gitlab::Geo::Fdw).to receive(:enabled?) { false }

              expect(subject.perform_checks).to match(/Geo database is not configured to use Foreign Data Wrapper/)
            end

            context 'when foreign tables are not up-to-date' do
              before do
                allow(Gitlab::Geo::Fdw).to receive(:foreign_tables_up_to_date?) { false }
              end

              it 'returns an error when FDW remote table is not in sync but has same amount of tables' do
                allow(Gitlab::Geo::Fdw).to receive(:foreign_schema_tables_count) { 1 }
                allow(Gitlab::Geo::Fdw).to receive(:gitlab_schema_tables_count) { 1 }

                expect(subject.perform_checks).to match(/Geo database has an outdated FDW remote schema\./)
              end

              it 'returns an error when FDW remote table is not in sync and has same different amount of tables' do
                allow(Gitlab::Geo::Fdw).to receive(:foreign_schema_tables_count) { 1 }
                allow(Gitlab::Geo::Fdw).to receive(:gitlab_schema_tables_count) { 2 }

                expect(subject.perform_checks).to match(/Geo database has an outdated FDW remote schema\. It contains [0-9]+ of [0-9]+ expected tables/)
              end
            end

            it 'finally returns an empty string when everything is healthy' do
              expect(subject.perform_checks).to be_blank
            end
          end
        end
      end
    end
  end

  describe '#db_replication_lag_seconds' do
    before do
      query = 'SELECT CASE WHEN pg_last_xlog_receive_location() = pg_last_xlog_receive_location() THEN 0 ELSE EXTRACT (EPOCH FROM now() - pg_last_xact_replay_timestamp())::INTEGER END AS replication_lag'
      allow(subject).to receive(:db_replication_lag_seconds_query).and_return(query)
      allow(ActiveRecord::Base).to receive_message_chain('connection.execute').with(no_args).with(query).and_return([{ 'replication_lag' => lag_in_seconds }])
    end

    context 'when there is no lag' do
      let(:lag_in_seconds) { nil }

      it 'returns 0 seconds' do
        expect(subject.db_replication_lag_seconds).to eq(0)
      end
    end

    context 'when there is lag' do
      let(:lag_in_seconds) { 7 }

      it 'returns the number of seconds' do
        expect(subject.db_replication_lag_seconds).to eq(7)
      end
    end
  end
end
