# frozen_string_literal: true

module Ci
  module Sources
    class Project < ActiveRecord::Base
      self.table_name = "ci_sources_projects"

      belongs_to :project, class_name: '::Project'

      belongs_to :source_project, class_name: '::Project', foreign_key: :source_project_id

      validates :project, presence: true
      validates :source_project, presence: true
    end
  end
end
