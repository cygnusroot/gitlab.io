# frozen_string_literal: true

module IncidentManagement
  class CreateIssueService < BaseService
    include Gitlab::Utils::StrongMemoize

    def execute
      return error('disabled') unless incident_management_setting.create_issue?
      return error('alert invalid') unless alert.valid?

      issue = create_issue(alert)

      success(issue: issue)
    end

    private

    def create_issue(alert)
      Issues::CreateService.new(
        project,
        issue_author,
        title: issue_title,
        description: issue_description
      ).execute
    end

    def issue_author
      strong_memoize(:issue_author) do
        # This is a temporary solution before we've implemented User.alert_bot
        # https://gitlab.com/gitlab-org/gitlab-ee/issues/10159
        User.ghost
      end
    end

    def issue_title
      alert.title
    end

    def issue_description
      return alert_summary unless issue_template_content

      horizontal_line = "\n---\n\n"

      alert_summary + horizontal_line + issue_template_content
    end

    def alert_summary
      annotation_list = annotations_as_list(alert.annotations)

      <<~MARKDOWN
        ## Summary

        #{annotation_list}
      MARKDOWN
    end

    def annotations_as_list(annotations)
      annotations
        .map { |annotation| "* #{annotation.label}: #{annotation.value}" }
        .join("\n")
    end

    def alert
      strong_memoize(:alert) do
        Gitlab::Alerting::Alert.new(project: project, payload: params)
      end
    end

    def issue_template_content
      incident_management_setting.issue_template_content
    end

    def incident_management_setting
      strong_memoize(:incident_management_setting) do
        project.incident_management_setting ||
          project.build_incident_management_setting
      end
    end
  end
end
