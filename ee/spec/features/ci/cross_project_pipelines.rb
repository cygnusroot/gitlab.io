require 'spec_helper'

describe 'Cross-Project Pipelines' do
  let(:user) { create(:user) }
  let(:upstream_project) { create(:project, :repository) }
  let(:downstream_project) { create(:project, :repository) }

  before do
    login_as(user)

    create(:ci_pipeline, :running,
           project: upstream_project,
           user: user,
           ref: upstream_project.default_branch)
  end

  context 'when cross-project pipelines are enabled' do
    before do
      stub_licensed_features(cross_project_pipelines: true)
    end

    context 'when the downstream project has an upstream project defined' do
      before do
        downstream_project.upstream_projects << upstream_project
      end

      context 'when user has permissions' do
        before do
          upstream_project.add_maintainer(user)
          downstream_project.add_maintainer(user)
        end

        it 'triggers a downstream pipeline when an upstream pipeline finishes' do
          expect { upstream_project.ci_pipelines.first.succeed! }
            .to change { downstream_project.ci_pipelines.count }.from(0).to(1)
        end
      end

      context 'when the user does not have permissions' do
        it 'does not trigger a downstream pipeline' do
          expect { upstream_project.ci_pipelines.first.succeed! }
            .to raise_error(Ci::CreateDownstreamProjectPipelineService::DownstreamPipelineCreationError)

          expect(downstream_project.ci_pipelines.count).to eq(0)
        end
      end
    end

    context 'when the downstream project does not have an upstream project defined' do
      before do
        upstream_project.add_maintainer(user)
        downstream_project.add_maintainer(user)
      end

      it 'does not trigger a downstream pipeline' do
        expect { upstream_project.ci_pipelines.first.succeed! }
          .not_to change { downstream_project.ci_pipelines.count }
      end
    end
  end

  context 'when cross-project pipelines are disabled' do
    before do
      stub_licensed_features(cross_project_pipelines: false)

      downstream_project.upstream_projects << upstream_project

      upstream_project.add_maintainer(user)
      downstream_project.add_maintainer(user)
    end

    it 'does not trigger a downstream pipeline' do
      expect { upstream_project.ci_pipelines.first.succeed! }
        .to raise_error(Ci::CreateDownstreamProjectPipelineService::DownstreamPipelineCreationError)

      expect(downstream_project.ci_pipelines.count).to eq(0)
    end
  end
end
