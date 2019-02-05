# frozen_string_literal: true

# Finder for retrieving project registries that have been synced
# scoped to a type (repository or wiki).
#
# Basic usage:
#
#     Geo::ProjectRegistrySyncedFinder.new(:repository).execute
#
# Valid `type` values are:
#
# * `:repository`
# * `:wiki`
#
# Any other value will be ignored.
module Geo
  class ProjectRegistrySyncedFinder
    attr_reader :type

    def initialize(type)
      @type = type.to_sym
    end

    def execute
      case type
      when :repository
        current_node.registries.synced_repos
      when :wiki
        current_node.registries.synced_wikis
      else
        Geo::ProjectRegistry.none
      end
    end

    private

    def current_node
      Geo::Fdw::GeoNode.current_node
    end
  end
end
