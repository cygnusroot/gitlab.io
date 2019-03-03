# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Config
        module Entry
          ##
          # Entry that represents a cross-project upstream trigger.
          #
          class TriggeredBy < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable

            validations { validates :config, presence: true, type: String }

            def value
              { project: @config }
            end
          end
        end
      end
    end
  end
end
