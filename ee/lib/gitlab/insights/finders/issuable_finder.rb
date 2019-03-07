module Gitlab
  module Insights
    module Finders
      class IssuableFinder
        attr_reader :entity, :current_user, :opts, :issuables
        attr_accessor :period_normalizer, :period_format

        def initialize(entity, current_user, opts)
          @entity = entity
          @current_user = current_user
          @opts = opts
        end

        # Returns an Active Record relation of issuables.
        def find
          relation = finder
            .new(current_user, finder_args)
            .execute
          relation = relation.joins(:labels) if opts.key?(:collection_labels)

          relation
        end

        private

        def finder
          case opts[:issuable_type]
          when 'issue'
            IssuesFinder
          when 'merge_request'
            MergeRequestsFinder
          else
            raise "Invalid value for `issuable_type`: #{opts[:issuable_type]}. Allowed values are `issue`, `merge_request`!"
          end
        end

        def finder_args
          args = {
            state: opts[:issuable_state] || 'opened',
            label_name: opts[:filter_labels],
            sort: 'created_asc'
          }

          case entity
          when Project
            args[:project_id] = entity.id
          when Namespace
            args[:group_id] = entity.id
          else
            raise "Entity class #{entity.class} (of #{entity}) is not supported!"
          end

          args[:created_after] = created_after_argument

          args
        end

        def created_after_argument
          case opts[:group_by]
          when 'day'
            self.period_format = "%d %b %y"
            (opts[:period_limit] || 30).to_i.days.ago
          when 'week'
            self.period_format = "%d %b %y"
            (opts[:period_limit] || 4).to_i.weeks.ago
          when 'month'
            self.period_format = "%B %Y"
            (opts[:period_limit] || 12).to_i.months.ago
          else
            raise "Invalid value for `group_by`: #{opts[:group_by]}. Allowed values are `day`, `week`, `month`!"
          end
        end

        def select_fields
          [:created_at].tap do |fields|
            fields << :labels if opts.key?(:collection_labels)
          end
        end
      end
    end
  end
end
