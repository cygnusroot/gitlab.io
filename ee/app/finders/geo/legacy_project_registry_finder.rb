# frozen_string_literal: true

module Geo
  class LegacyProjectRegistryFinder < RegistryFinder
    def synced_repositories
      if selective_sync?
        legacy_find_synced_repositories
      else
        find_synced_repositories
      end
    end

    def synced_wikis
      if use_legacy_queries?
        legacy_find_synced_wikis
      else
        find_synced_wikis
      end
    end

    private

    def legacy_find_synced_repositories
      legacy_find_project_registries(Geo::ProjectRegistry.synced_repos)
    end

    def legacy_find_synced_wikis
      legacy_find_project_registries(Geo::ProjectRegistry.synced_wikis)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_project_registries(project_registries)
      legacy_inner_join_registry_ids(
        current_node.projects,
        project_registries.pluck(:project_id),
        Project
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def find_synced_repositories
      Geo::ProjectRegistry.synced_repos
    end

    def find_synced_wikis
      Geo::ProjectRegistry.synced_wikis
    end
  end
end
