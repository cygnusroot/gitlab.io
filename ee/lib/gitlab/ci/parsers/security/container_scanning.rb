# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class ContainerScanning < Base
          REPORT_TYPE = 'container_scanning'
          ContainerScanningParserError = Class.new(StandardError)

          def self.report_type
            REPORT_TYPE
          end

          def parse!(json_data, report)
            super
          rescue JSON::ParserError => e
            raise ContainerScanningParserError, "JSON parsing failed: #{e.message}"
          rescue => e
            raise ContainerScanningParserError, "Container Scanning report parsing failed: #{e.message}"
          end
        end
      end
    end
  end
end
