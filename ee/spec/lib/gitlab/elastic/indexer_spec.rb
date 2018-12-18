require 'spec_helper'

describe Gitlab::Elastic::Indexer do
  include StubENV

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'true')
    stub_ee_application_setting(elasticsearch_url: ['http://localhost:9200'])
  end

  let(:project)  { create(:project, :repository) }
  let(:from_sha) { Gitlab::Git::BLANK_SHA }
  let(:to_sha)   { project.commit.try(:sha) }
  let(:indexer)  { described_class.new(project)  }

  let(:popen_success) { [[''], 0] }
  let(:popen_failure) { [['error'], 1] }

  context 'empty project' do
    let(:project) { create(:project) }

    it 'updates the index status without running the indexing command' do
      expect_popen.never

      indexer.run

      expect_index_status(Gitlab::Git::BLANK_SHA)
    end
  end

  context 'repository has unborn head' do
    it 'updates the index status without running the indexing command' do
      allow(project.repository).to receive(:exists?).and_return(false)
      expect_popen.never

      indexer.run

      expect_index_status(Gitlab::Git::BLANK_SHA)
    end
  end

  context 'test project' do
    let(:project) { create(:project, :repository) }

    it 'runs the indexing command' do
      expect_popen.with(
        [
          'gitlab-elasticsearch-indexer',
          project.id.to_s,
          Gitlab::GitalyClient::StorageSettings.allow_disk_access { project.repository.path_to_repo }
        ],
        nil,
        hash_including(
          'ELASTIC_CONNECTION_INFO' => Gitlab::CurrentSettings.elasticsearch_config.to_json,
          'RAILS_ENV'               => Rails.env,
          'FROM_SHA'                => from_sha,
          'TO_SHA'                  => to_sha
        )
      ).and_return(popen_success)

      indexer.run(from_sha, to_sha)
    end

    it 'updates the index status when the indexing is a success' do
      expect_popen.and_return(popen_success)

      indexer.run(from_sha, to_sha)

      expect_index_status(to_sha)
    end

    it 'leaves the index status untouched when indexing a non-HEAD commit' do
      expect_popen.and_return(popen_success)

      indexer.run(from_sha, project.repository.commit('HEAD~1'))

      expect(project.index_status).to be_nil
    end

    it 'leaves the index status untouched when the indexing fails' do
      expect_popen.and_return(popen_failure)

      expect { indexer.run }.to raise_error(Gitlab::Elastic::Indexer::Error)

      expect(project.index_status).to be_nil
    end
  end

  def expect_popen
    expect(Gitlab::Popen).to receive(:popen)
  end

  def expect_index_status(sha)
    status = project.index_status

    expect(status).not_to be_nil
    expect(status.indexed_at).not_to be_nil
    expect(status.last_commit).to eq(sha)
  end
end
