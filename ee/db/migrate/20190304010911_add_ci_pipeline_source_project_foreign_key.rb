# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddCiPipelineSourceProjectForeignKey < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_sources_projects, :projects, column: :project_id

    add_concurrent_foreign_key :ci_sources_projects, :projects, column: :source_project_id
  end

  def down
    remove_foreign_key :ci_sources_projects, column: :project_id

    remove_foreign_key :ci_sources_projects, column: :source_project_id
  end
end
