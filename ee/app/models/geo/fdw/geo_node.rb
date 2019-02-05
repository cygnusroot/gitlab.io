# frozen_string_literal: true

module Geo
  module Fdw
    class GeoNode < ::Geo::BaseFdw
      include ::Geo::SelectiveSync

      self.primary_key = :id
      self.inheritance_column = nil
      self.table_name = Gitlab::Geo::Fdw.foreign_table_name('geo_nodes')

      serialize :selective_sync_shards, Array # rubocop:disable Cop/ActiveRecordSerialize

      has_many :geo_node_namespace_links, class_name: 'Geo::Fdw::GeoNodeNamespaceLink'
      has_many :namespaces, class_name: 'Geo::Fdw::Namespace', through: :geo_node_namespace_links

      def project_registries
        return Geo::ProjectRegistry.all unless selective_sync?

        if selective_sync_by_namespaces?
          registries_for_selected_namespaces
        elsif selective_sync_by_shards?
          registries_for_selected_shards
        else
          Geo::ProjectRegistry.none
        end
      end

      private

      def registries_for_selected_namespaces
        query = Gitlab::ObjectHierarchy.new(namespaces).base_and_descendants

        Geo::ProjectRegistry
          .joins(fdw_inner_join_projects)
          .where(fdw_projects_table.name => { namespace_id: query.select(:id) })
      end

      def registries_for_selected_shards
        Geo::ProjectRegistry
          .joins(fdw_inner_join_projects)
          .where(fdw_projects_table.name => { repository_storage: selective_sync_shards })
      end

      def project_registries_table
        Geo::ProjectRegistry.arel_table
      end

      def fdw_projects_table
        Geo::Fdw::Project.arel_table
      end

      def fdw_inner_join_projects
        project_registries_table
          .join(fdw_projects_table, Arel::Nodes::InnerJoin)
          .on(project_registries_table[:project_id].eq(fdw_projects_table[:id]))
          .join_sources
      end
    end
  end
end
