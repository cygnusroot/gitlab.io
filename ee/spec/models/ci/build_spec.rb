require 'spec_helper'

describe Ci::Build do
  set(:group) { create(:group, :access_requestable, plan: :bronze_plan) }
  let(:project) { create(:project, :repository, group: group) }

  let(:pipeline) do
    create(:ci_pipeline, project: project,
                         sha: project.commit.id,
                         ref: project.default_branch,
                         status: 'success')
  end

  let(:job) { create(:ci_build, pipeline: pipeline) }

  describe '#shared_runners_minutes_limit_enabled?' do
    subject { job.shared_runners_minutes_limit_enabled? }

    context 'for shared runner' do
      before do
        job.runner = create(:ci_runner, :instance)
      end

      it do
        expect(job.project).to receive(:shared_runners_minutes_limit_enabled?)
          .and_return(true)

        is_expected.to be_truthy
      end
    end

    context 'with specific runner' do
      before do
        job.runner = create(:ci_runner, :project)
      end

      it { is_expected.to be_falsey }
    end

    context 'without runner' do
      it { is_expected.to be_falsey }
    end
  end

  context 'updates pipeline minutes' do
    let(:job) { create(:ci_build, :running, pipeline: pipeline) }

    %w(success drop cancel).each do |event|
      it "for event #{event}" do
        expect(UpdateBuildMinutesService)
          .to receive(:new).and_call_original

        job.public_send(event)
      end
    end
  end

  describe '#stick_build_if_status_changed' do
    it 'sticks the build if the status changed' do
      job = create(:ci_build, :pending)

      allow(Gitlab::Database::LoadBalancing).to receive(:enable?)
        .and_return(true)

      expect(Gitlab::Database::LoadBalancing::Sticking).to receive(:stick)
        .with(:build, job.id)

      job.update(status: :running)
    end
  end

  describe '#variables' do
    subject { job.variables }

    context 'when environment specific variable is defined' do
      let(:environment_varialbe) do
        { key: 'ENV_KEY', value: 'environment', public: false }
      end

      before do
        job.update(environment: 'staging')
        create(:environment, name: 'staging', project: job.project)

        variable =
          build(:ci_variable,
                environment_varialbe.slice(:key, :value)
                  .merge(project: project, environment_scope: 'stag*'))

        variable.save!
      end

      context 'when variable environment scope is available' do
        before do
          stub_licensed_features(variable_environment_scope: true)
        end

        it { is_expected.to include(environment_varialbe) }
      end

      context 'when variable environment scope is not available' do
        before do
          stub_licensed_features(variable_environment_scope: false)
        end

        it { is_expected.not_to include(environment_varialbe) }
      end

      context 'when there is a plan for the group' do
        it 'GITLAB_FEATURES should include the features for that plan' do
          is_expected.to include({ key: 'GITLAB_FEATURES', value: anything, public: true })
          features_variable = subject.find { |v| v[:key] == 'GITLAB_FEATURES' }
          expect(features_variable[:value]).to include('multiple_ldap_servers')
        end
      end
    end
  end

  build_artifacts_methods = {
    has_performance_json?: {
      filename: Ci::Build::PERFORMANCE_FILE,
      job_names: %w[performance deploy]
    },
    has_license_management_json?: {
      filename: Ci::Build::LICENSE_MANAGEMENT_FILE,
      job_names: %w[license_management]
    }
  }

  build_artifacts_methods.each do |method, requirements|
    filename = requirements[:filename]
    job_names = requirements[:job_names]

    describe "##{method}" do
      job_names.each do |job_name|
        context "with a job named #{job_name} and a file named #{filename}" do
          let(:build) do
            create(
              :ci_build,
              :artifacts,
              name: job_name,
              pipeline: pipeline,
              options: {
                artifacts: {
                  paths: [filename, 'some-other-artifact.txt']
                }
              }
            )
          end

          it { expect(build.send(method)).to be_truthy }
        end
      end

      context 'with an invalid filename' do
        let(:build) do
          create(
            :ci_build,
            :artifacts,
            name: job_names.first,
            pipeline: pipeline,
            options: {}
          )
        end

        it { expect(build.send(method)).to be_falsey }
      end

      context 'with an invalid job name' do
        let(:build) do
          create(
            :ci_build,
            :artifacts,
            pipeline: pipeline,
            options: {
              artifacts: {
                paths: [filename, 'some-other-artifact.txt']
              }
            }
          )
        end

        it { expect(build.send(method)).to be_falsey }
      end
    end
  end

  describe '.with_security_reports' do
    subject { described_class.with_security_reports }

    context 'when build has a security report' do
      let!(:build) { create(:ee_ci_build, :success, :security_reports) }

      it 'selects the build' do
        is_expected.to eq([build])
      end
    end

    context 'when build does not have security reports' do
      let!(:build) { create(:ci_build, :success, :trace_artifact) }

      it 'does not select the build' do
        is_expected.to be_empty
      end
    end

    context 'when there are multiple builds with security reports' do
      let!(:builds) { create_list(:ee_ci_build, 5, :success, :security_reports) }

      it 'does not execute a query for selecting job artifacts one by one' do
        recorded = ActiveRecord::QueryRecorder.new do
          subject.each do |build|
            build.job_artifacts.map { |a| a.file.exists? }
          end
        end

        expect(recorded.count).to eq(2)
      end
    end
  end

  describe '#collect_security_reports!' do
    let(:security_reports) { ::Gitlab::Ci::Reports::Security::Reports.new }

    subject { job.collect_security_reports!(security_reports) }

    before do
      stub_licensed_features(sast: true)
    end

    context 'when build has a security report' do
      context 'when there is a sast report' do
        before do
          create(:ee_ci_job_artifact, :sast, job: job, project: job.project)
        end

        it 'parses blobs and add the results to the report' do
          expect { subject }.not_to raise_error

          expect(security_reports.get_report('sast').occurrences.size).to eq(3)
        end
      end

      context 'when there is a corrupted sast report' do
        before do
          create(:ee_ci_job_artifact, :sast_with_corrupted_data, job: job, project: job.project)
        end

        it 'raises an error' do
          expect { subject }.to raise_error(::Gitlab::Ci::Parsers::Security::Sast::SastParserError)
        end
      end
    end
  end

  describe '#collect_license_management_reports!' do
    subject { job.collect_license_management_reports!(license_management_report) }

    let(:license_management_report) { Gitlab::Ci::Reports::LicenseManagement::Report.new }

    it { expect(license_management_report.licenses.count).to eq(0) }

    context 'when build has a license management report' do
      context 'when there is a license management report' do
        before do
          create(:ee_ci_job_artifact, :license_management_report, job: job, project: job.project)
        end

        it 'parses blobs and add the results to the report' do
          expect { subject }.not_to raise_error

          expect(license_management_report.licenses.count).to eq(4)
          expect(license_management_report.licenses[0].name).to eq('MIT')
          expect(license_management_report.licenses[0].dependencies.count).to eq(52)
        end
      end

      context 'when there is a corrupted license management report' do
        before do
          create(:ee_ci_job_artifact, :corrupted_license_management_report, job: job, project: job.project)
        end

        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Ci::Parsers::LicenseManagement::LicenseManagement::LicenseManagementParserError)
        end
      end
    end
  end
end
