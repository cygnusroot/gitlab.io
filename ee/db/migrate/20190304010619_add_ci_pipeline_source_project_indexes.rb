# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddCiPipelineSourceProjectIndexes < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_sources_projects, :project_id

    add_concurrent_index :ci_sources_projects, :source_project_id
  end

  def down
    remove_concurrent_index :ci_sources_projects, :project_id if index_exists? :ci_sources_projects, :project_id

    remove_concurrent_index :ci_sources_projects, :source_project_id if index_exists? :ci_sources_projects, :source_project_id
  end
end
