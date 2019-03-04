# frozen_string_literal: true

require 'spec_helper'

describe Ci::CreateDownstreamProjectsPipelineWorker do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, project: project, user: user) }

  let(:service) { double('pipeline creation service') }

  describe '#perform' do
    context 'when pipeline exists' do
      context 'when downstream projects exist' do
        let(:downstream_project) { create(:project) }

        before do
          project.downstream_projects << downstream_project
        end

        it 'calls downstream project pipeline creation service' do
          expect(::Ci::CreateDownstreamProjectPipelineService)
            .to receive(:new)
            .with(project, user)
            .and_return(service)

          expect(service).to receive(:execute).with(downstream_project, user)

          described_class.new.perform(pipeline.id)
        end
      end

      context 'when downstream projects do not exist' do
        it 'does nothing' do
          expect(::Ci::CreateDownstreamProjectPipelineService)
            .not_to receive(:new)

          described_class.new.perform(pipeline.id)
        end
      end
    end

    context 'when pipeline does not exist' do
      it 'does nothing' do
        expect(::Ci::CreateDownstreamProjectPipelineService)
          .not_to receive(:new)

        described_class.new.perform(1234)
      end
    end
  end
end
