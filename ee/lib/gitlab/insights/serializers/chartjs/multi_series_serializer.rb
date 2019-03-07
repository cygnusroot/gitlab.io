module Gitlab
  module Insights
    module Serializers
      module Chartjs
        class MultiSeriesSerializer < BaseSerializer
          # Returns the series data as a hash, e.g.
          #   {
          #     Manage: [1, 2],
          #     Plan: [2, 1]
          #   }
          def build_series_data
            insights.each_with_object(Hash.new { |h, k| h[k] = [] }) do |(_, data), series_data|
              data.each do |serie_name, count|
                series_data[serie_name] << count
              end
            end
          end
        end
      end
    end
  end
end
