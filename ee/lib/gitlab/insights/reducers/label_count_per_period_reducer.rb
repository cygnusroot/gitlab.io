module Gitlab
  module Insights
    module Reducers
      class LabelCountPerPeriodReducer < CountPerPeriodReducer
        def initialize(issuables, labels:, period:, order_field: :created_at)
          super(issuables, period: period, order_field: order_field)
          @labels = labels

          validate!
        end

        private

        attr_reader :labels

        # Returns a hash { label => issuables_count }, e.g.
        #   {
        #     'Manage' => 2,
        #     'Plan' => 3,
        #     'undefined' => 1
        #   }
        def value_for_period(issuables)
          Gitlab::Insights::Reducers::CountPerLabelReducer.reduce(issuables, labels: labels)
        end
      end
    end
  end
end
