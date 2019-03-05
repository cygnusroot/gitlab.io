# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Pipeline
        module Chain
          module Create
            extend ::Gitlab::Utils::Override

            override :perform!
            def perform!
              if pipeline.default_branch? && cross_project_pipelines_enabled?
                bridges = pipeline.stages.map(&:bridges).flatten

                project.upstream_projects = bridges.map do |bridge|
                  ::Project.find_by_full_path(bridge.target_project_path) if bridge.upstream_bridge?
                end.compact
              end

              super
            end

            private

            def cross_project_pipelines_enabled?
              project.feature_available?(:cross_project_pipelines)
            end
          end
        end
      end
    end
  end
end
