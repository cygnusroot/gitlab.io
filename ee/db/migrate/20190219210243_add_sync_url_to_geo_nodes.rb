# frozen_string_literal: true

class AddSyncUrlToGeoNodes < ActiveRecord::Migration[5.0]
  def change
    add_column :geo_nodes, :sync_url, :string
  end
end

