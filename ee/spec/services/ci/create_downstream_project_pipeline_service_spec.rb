# frozen_string_literal: true

require 'spec_helper'

describe Ci::CreateDownstreamProjectPipelineService, '#execute' do
  let(:user) { create(:user) }
  let(:upstream_project) { create(:project, :repository) }
  let(:downstream_project) { create(:project, :repository) }

  let(:upstream_pipeline) do
    create(:ci_pipeline, :running, project: upstream_project)
  end

  let(:service) { described_class.new(upstream_project, user) }

  before do
    stub_ci_pipeline_to_return_yaml_file
    upstream_project.add_developer(user)
  end

  context 'when cross project pipelines are enabled' do
    before do
      stub_licensed_features(cross_project_pipelines: true)
    end

    context 'when user can create pipeline in a downstream project' do
      before do
        downstream_project.add_developer(user)
      end

      it 'creates only one new pipeline' do
        expect { service.execute(downstream_project, user) }
          .to change { Ci::Pipeline.count }.by(1)
      end

      it 'creates a new pipeline in a downstream project' do
        pipeline = service.execute(downstream_project, user)

        expect(pipeline.user).to eq user
        expect(pipeline.project).to eq downstream_project
      end
    end

    context 'when user can not access downstream project' do
      it 'raises an error' do
        expect { service.execute(downstream_project, user) }
          .to raise_error(Ci::CreateDownstreamProjectPipelineService::DownstreamPipelineCreationError)
      end
    end

    context 'when user does not have access to create pipeline' do
      before do
        downstream_project.add_guest(user)
      end

      it 'raises an error' do
        expect { service.execute(downstream_project, user) }
          .to raise_error(Ci::CreateDownstreamProjectPipelineService::DownstreamPipelineCreationError)
      end
    end
  end

  context 'when cross project pipelines are not enabled' do
    before do
      stub_licensed_features(cross_project_pipelines: false)
    end

    it 'raises an error' do
      expect { service.execute(downstream_project, user) }
        .to raise_error(Ci::CreateDownstreamProjectPipelineService::DownstreamPipelineCreationError)
    end
  end
end
