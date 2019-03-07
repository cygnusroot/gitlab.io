module Gitlab
  module Insights
    module Reducers
      class BaseReducer
        def self.reduce(issuables, **args)
          new(issuables, **args).reduce
        end

        def initialize(issuables)
          @issuables = issuables
        end
        private_class_method :new

        def reduce
          raise NotImplementedError
        end

        private

        attr_reader :issuables
      end
    end
  end
end
