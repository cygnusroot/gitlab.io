# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddExtraSharedRunnersMinutesLimitToNamespaces < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def change
    add_column :namespaces, :extra_shared_runners_minutes_limit, :integer
  end
end
