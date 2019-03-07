module Gitlab
  module Insights
    module Serializers
      module Chartjs
        class BarSerializer < BaseSerializer
          private

          # series_data - The series hash, e.g.
          #   {
          #     Manage: 1,
          #     Plan: 2
          #   }
          #
          # Returns a datasets array, e.g.
          #   [{ label: nil, data: [1, 2], borderColor: ['red', 'blue'] }]
          def chart_datasets(series_data)
            background_colors = series_data.keys.map { |name| generate_color_code(name) }

            [dataset(nil, series_data.values, background_colors)]
          end
        end
      end
    end
  end
end
