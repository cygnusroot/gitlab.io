require 'spec_helper'

describe Clusters::CreateService do
  let(:access_token) { 'xxx' }
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:result) { described_class.new(project, user, params).execute(access_token) }

  context 'when provider is gcp' do
    context 'when project has no clusters' do
      context 'when correct params' do
        let(:params) do
          {
            name: 'test-cluster',
            provider_type: :gcp,
            provider_gcp_attributes: {
              gcp_project_id: 'gcp-project',
              zone: 'us-central1-a',
              num_nodes: 1,
              machine_type: 'machine_type-a'
            }
          }
        end

        it 'creates a cluster object and performs a worker' do
          expect(ClusterProvisionWorker).to receive(:perform_async)

          expect { result }
            .to change { Clusters::Cluster.count }.by(1)
            .and change { Clusters::Providers::Gcp.count }.by(1)

          expect(result.name).to eq('test-cluster')
          expect(result.user).to eq(user)
          expect(result.project).to eq(project)
          expect(result.provider.gcp_project_id).to eq('gcp-project')
          expect(result.provider.zone).to eq('us-central1-a')
          expect(result.provider.num_nodes).to eq(1)
          expect(result.provider.machine_type).to eq('machine_type-a')
          expect(result.provider.access_token).to eq(access_token)
          expect(result.platform).to be_nil
        end
      end

      context 'when invalid params' do
        let(:params) do
          {
            name: 'test-cluster',
            provider_type: :gcp,
            provider_gcp_attributes: {
              gcp_project_id: '!!!!!!!',
              zone: 'us-central1-a',
              num_nodes: 1,
              machine_type: 'machine_type-a'
            }
          }
        end

        it 'returns an error' do
          expect(ClusterProvisionWorker).not_to receive(:perform_async)
          expect { result }.to change { Clusters::Cluster.count }.by(0)
          expect(result.errors[:"provider_gcp.gcp_project_id"]).to be_present
        end
      end
    end

    context 'when project has a cluster' do
      let(:params) do
        {
          name: 'test-cluster',
          provider_type: :gcp,
          provider_gcp_attributes: {
            gcp_project_id: 'gcp-project',
            zone: 'us-central1-a',
            num_nodes: 1,
            machine_type: 'machine_type-a'
          }
        }
      end

      before do
        Clusters::Cluster.create(params.merge(user: user, projects: [project]))
      end

      context 'when project does not have multiple cluster available' do
        before do
          allow(License).to receive(:feature_available?).with(:multiple_clusters).and_return(false)
        end

        it 'does not create a cluster' do
          expect(ClusterProvisionWorker).not_to receive(:perform_async)
          expect { result }.to change { Clusters::Cluster.count }.by(0)
        end
      end

      context 'when project has multiple clusters available' do
        before do
          allow(License).to receive(:feature_available?).with(:multiple_clusters).and_return(true)
        end

        it 'creates a cluster' do
          expect(ClusterProvisionWorker).to receive(:perform_async)
          expect { result }.to change { Clusters::Cluster.count }.by(1)
        end
      end
    end
  end
end
