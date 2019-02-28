# frozen_string_literal: true

module IncidentManagement
  class ProjectIncidentManagementSetting < ApplicationRecord
    include Gitlab::Utils::StrongMemoize

    belongs_to :project

    validate :issue_template_exists, if: :create_issue?

    def issue_template_content
      strong_memoize(:issue_template_content) do
        load_issue_template_content
      end
    end

    private

    def issue_template_exists
      return unless issue_template_key.present?

      Gitlab::Template::IssueTemplate.find(issue_template_key, project)
    rescue Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError
      errors.add(:issue_template_key, 'not found')
    end

    def load_issue_template_content
      return unless issue_template_key.present?

      Gitlab::Template::IssueTemplate.find(issue_template_key, project).content
    rescue Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError
    end
  end
end
