# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreatePipelineSourceProject < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :ci_sources_projects, force: :cascade do |t|
      t.integer :project_id

      t.integer :source_project_id
    end
  end
end
