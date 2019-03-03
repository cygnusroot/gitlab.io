# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Config
        module Entry
          ##
          # Entry that represents a CI/CD Bridge job that is responsible for
          # defining a downstream or upstream project trigger.
          #
          class Bridge < ::Gitlab::Config::Entry::Simplifiable
            strategy :DownstreamBridge, if: -> (config) { config.has_key?(:trigger) }
            strategy :UpstreamBridge, if: -> (config) { config.has_key?(:triggered_by) }

            class DownstreamBridge < ::Gitlab::Config::Entry::Node
              include ::Gitlab::Config::Entry::Configurable
              include ::Gitlab::Config::Entry::Attributable

              ALLOWED_KEYS = %i[trigger stage allow_failure only except when extends variables].freeze

              validations do
                validates :config, presence: true
                validates :config, allowed_keys: ALLOWED_KEYS
                validates :trigger, presence: true
                validates :name, presence: true
                validates :name, type: Symbol

                with_options allow_nil: true do
                  validates :when,
                    inclusion: { in: %w[on_success on_failure always],
                                 message: 'should be on_success, on_failure or always' }
                  validates :extends, type: String
                end
              end

              entry :trigger, ::EE::Gitlab::Ci::Config::Entry::Trigger,
                description: 'CI/CD Bridge downstream trigger definition.'

              entry :stage, ::Gitlab::Ci::Config::Entry::Stage,
                description: 'Pipeline stage this job will be executed into.'

              entry :only, ::Gitlab::Ci::Config::Entry::Policy,
                description: 'Refs policy this job will be executed for.',
                default: ::Gitlab::Ci::Config::Entry::Policy::DEFAULT_ONLY

              entry :except, ::Gitlab::Ci::Config::Entry::Policy,
                description: 'Refs policy this job will be executed for.'

              entry :variables, ::Gitlab::Ci::Config::Entry::Variables,
                description: 'Environment variables available for this job.'

              helpers(*ALLOWED_KEYS)
              attributes(*ALLOWED_KEYS)

              def name
                @metadata[:name]
              end

              def value
                { name: name,
                  trigger: trigger_value,
                  ignore: !!allow_failure,
                  stage: stage_value,
                  when: when_value,
                  extends: extends_value,
                  variables: (variables_value if variables_defined?),
                  only: only_value,
                  except: except_value }.compact
              end
            end

            class UpstreamBridge < ::Gitlab::Config::Entry::Node
              include ::Gitlab::Config::Entry::Configurable
              include ::Gitlab::Config::Entry::Attributable

              ALLOWED_KEYS = %i[triggered_by stage variables].freeze

              validations do
                validates :config, presence: true
                validates :config, allowed_keys: ALLOWED_KEYS
                validates :triggered_by, presence: true
                validates :name, presence: true
                validates :name, type: Symbol
              end

              entry :triggered_by, ::EE::Gitlab::Ci::Config::Entry::TriggeredBy,
                description: 'CI/CD Bridge downstream trigger definition.'

              entry :stage, ::Gitlab::Ci::Config::Entry::Stage,
                description: 'Pipeline stage this job will be executed into.'

              entry :variables, ::Gitlab::Ci::Config::Entry::Variables,
                description: 'Environment variables available for this job.'

              helpers(*ALLOWED_KEYS)
              attributes(*ALLOWED_KEYS)

              def name
                @metadata[:name]
              end

              def value
                { name: name,
                  triggered_by: triggered_by_value,
                  stage: stage_value,
                  variables: (variables_value if variables_defined?) }.compact
              end
            end

            class UnknownStrategy < ::Gitlab::Config::Entry::Node
              def errors
                ["#{location} has to be either an upstream or downstream bridge"]
              end
            end
          end
        end
      end
    end
  end
end
