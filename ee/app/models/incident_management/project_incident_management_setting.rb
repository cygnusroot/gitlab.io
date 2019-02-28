# frozen_string_literal: true

module IncidentManagement
  class ProjectIncidentManagementSetting < ApplicationRecord
    include Gitlab::Utils::StrongMemoize

    belongs_to :project

    validate :issue_template_exists, if: :create_issue?

    def issue_template_content
      strong_memoize(:issue_template_content) { load_issue_template_content }
    end

    private

    def issue_template_exists
      return unless issue_template_key.present?

      errors.add(:issue_template_key, 'not found') unless find_issue_template
    end

    def load_issue_template_content
      return unless issue_template_key.present?

      find_issue_template&.content
    end

    def find_issue_template
      Gitlab::Template::IssueTemplate.find(issue_template_key, project)
    rescue Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError
    end
  end
end
