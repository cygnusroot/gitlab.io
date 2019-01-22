require 'spec_helper'

describe Ci::CreateCrossProjectPipelineWorker do
  set(:user) { create(:user) }
  set(:project) { create(:project) }
  set(:pipeline) { create(:ci_pipeline, project: project) }
  set(:bridge) { create(:ci_bridge, user: user, pipeline: pipeline) }

  let(:service) { double('pipeline creation service') }

  describe '#perform' do
    context 'when bridge exists' do
      it 'calls cross project pipeline creation service' do
        expect(Ci::CreateCrossProjectPipelineService)
          .to receive(:new)
          .with(project, user)
          .and_return(service)

        expect(service).to receive(:execute).with(bridge)

        described_class.new.perform(bridge.id)
      end
    end
  end
end
