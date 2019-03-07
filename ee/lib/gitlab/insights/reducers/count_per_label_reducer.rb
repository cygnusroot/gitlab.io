module Gitlab
  module Insights
    module Reducers
      class CountPerLabelReducer < BaseReducer
        def initialize(issuables, labels:)
          super(issuables)
          @labels = labels

          validate!
        end

        # Returns a hash { label => issuables_count }, e.g.
        #   {
        #     'Manage' => 2,
        #     'Plan' => 3,
        #     'undefined' => 1
        #   }
        def reduce
          count_per_label
        end

        private

        attr_reader :labels

        def validate!
          raise "Invalid value for `labels`: it must be an array!" unless Array(labels).any?
        end

        def count_per_label
          final_hash = Array(labels).each_with_object({}) do |label, hash|
            issuables_with_label = issuables.select { |issuable| issuable.labels.pluck(:title).include?(label) }
            @issuables -= issuables_with_label
            hash[label] = issuables_with_label.size
          end

          # those that do not fall into the collection labels should also be displayed
          final_hash[Gitlab::Insights::UNCATEGORIZED] = issuables.size

          final_hash
        end
      end
    end
  end
end
