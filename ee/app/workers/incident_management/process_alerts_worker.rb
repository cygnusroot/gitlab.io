# frozen_string_literal: true

module IncidentManagement
  class ProcessAlertsWorker
    include ApplicationWorker

    queue_namespace :incident_management

    def perform(project_id, alerts)
      return unless alerts.any?

      project = find_project(project_id)
      return unless project

      alerts.each do |alert|
        create_issue(project, alert)
      end
    end

    private

    def find_project(project_id)
      Project.find_by_id(project_id)
    end

    def create_issue(project, alert)
      IncidentManagement::CreateIssueService
        .new(project, nil, alert)
        .execute
    end
  end
end
