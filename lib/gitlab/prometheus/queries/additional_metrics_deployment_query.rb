module Gitlab
  module Prometheus
    module Queries
      class AdditionalMetricsDeploymentQuery < BaseQuery
        include QueryAdditionalMetrics

        def query(deployment_id)
          # TODO: Make this CE compat
          Deployment.find_by(id: deployment_id).try do |deployment|
            query_metrics(
              deployment.project,
              deployment.environment,
              common_query_context(
                deployment.environment,
                timeframe_start: (deployment.created_at - 30.minutes).to_f,
                timeframe_end: (deployment.created_at + 30.minutes).to_f
              )
            )
          end
        end
      end
    end
  end
end
