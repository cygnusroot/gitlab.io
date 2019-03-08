# frozen_string_literal: true

require 'spec_helper'

describe IncidentManagement::ProcessAlertsWorker do
  set(:project) { create(:project) }

  subject { described_class.new.perform(project.id, alerts) }

  context 'with alerts' do
    let(:alerts) { [:one, :two] }
    let(:create_issue_service) { spy(:create_issue_service) }

    it 'calls create issue service' do
      expect(Project).to receive(:find_by_id).and_call_original

      expect(IncidentManagement::CreateIssueService)
        .to receive(:new).with(project, nil, :one)
        .and_return(create_issue_service)

      expect(IncidentManagement::CreateIssueService)
        .to receive(:new).with(project, nil, :two)
        .and_return(create_issue_service)

      expect(create_issue_service).to receive(:execute).twice

      subject
    end

    context 'with invalid project' do
      let(:invalid_project_id) { 0 }

      subject { described_class.new.perform(invalid_project_id, alerts) }

      it 'does not create issues' do
        expect(Project).to receive(:find_by_id).and_call_original
        expect(IncidentManagement::CreateIssueService).not_to receive(:new)

        subject
      end
    end
  end

  context 'without alerts' do
    let(:alerts) { [] }

    it 'does nothing' do
      expect(Project).not_to receive(:find_by_id)
      expect(IncidentManagement::CreateIssueService).not_to receive(:new)

      subject
    end
  end
end
