require 'digest/md5'

module Gitlab
  module Insights
    module Serializers
      module Chartjs
        class BaseSerializer
          def self.present(insights)
            new(insights).present
          end

          def initialize(insights)
            @insights = insights
          end
          private_class_method :new

          # Return a Chartjs-compatible hash, e.g.
          #   {
          #     labels: ['January', 'February'],
          #     datasets: [
          #       { label: 'Manage', data: [1, 2], backgroundColor: 'red' },
          #       { label: 'Plan', data: [2, 1], backgroundColor: 'blue' }
          #     ]
          #   }
          def present
            chart_data(insights.keys, build_series_data)
          end

          private

          attr_reader :insights

          # labels - The series labels, e.g. ['January', 'February'].
          # raw_datasets - The datasets hash, e.g.
          #   {
          #     Manage: 1,
          #     Plan: 2
          #   }
          # or
          #   {
          #     Manage: [1, 2],
          #     Plan: [2, 1]
          #   }
          #
          # Return a Chartjs-compatible hash, e.g.
          #   {
          #     labels: ['January', 'February'],
          #     datasets: [
          #       { label: 'Manage', data: [1, 2], backgroundColor: 'red' },
          #       { label: 'Plan', data: [2, 1], backgroundColor: 'blue' }
          #     ]
          #   }
          def chart_data(labels, series_data)
            {
              labels: labels,
              datasets: chart_datasets(series_data)
            }.with_indifferent_access
          end

          # Can be overridden by subclasses.
          #
          # Returns the series data as a hash, e.g.
          #   {
          #     Manage: 1,
          #     Plan: 2
          #   }
          def build_series_data
            insights
          end

          # Can be overridden by subclasses.
          #
          # series_data - The series hash, e.g.
          #   {
          #     Manage: 1,
          #     Plan: 2
          #   }
          # or
          #   {
          #     Manage: [1, 2],
          #     Plan: [2, 1]
          #   }
          #
          # Returns a ChartJS-compatible datasets array, e.g.
          #   [
          #     { label: 'Manage', data: [1, 2], backgroundColor: 'red' },
          #     { label: 'Plan', data: [2, 1], backgroundColor: 'blue' }
          #   ]
          def chart_datasets(series_data)
            series_data.map do |name, data|
              dataset(name, data, generate_color_code(name))
            end
          end

          # Can be overridden by subclasses.
          #
          # label - The serie's label.
          # data - The serie's data array.
          # color - The serie's color.
          #
          # Returns a serie dataset, e.g.
          #   { label: 'Manage', data: [1, 2], backgroundColor: 'red' }
          def dataset(label, serie_data, color)
            {
              label: label,
              data: serie_data,
              backgroundColor: color
            }.with_indifferent_access
          end

          def generate_color_code(label)
            Gitlab::Insights::STATIC_COLOR_MAP[label] || "##{Digest::MD5.hexdigest(label.to_s)[0..5]}"
          end

          def default_color
            Gitlab::Insights::STATIC_COLOR_MAP[Gitlab::Insights::UNCATEGORIZED]
          end
        end
      end
    end
  end
end
