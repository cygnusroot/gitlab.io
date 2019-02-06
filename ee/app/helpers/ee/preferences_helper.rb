# frozen_string_literal: true

module EE
  module PreferencesHelper
    extend ::Gitlab::Utils::Override

    override :excluded_dashboard_choices
    def excluded_dashboard_choices
      return [] if can?(current_user, :read_operations_dashboard)

      super
    end

    def group_view_choices
      strong_memoize(:group_view_choices) do
        [[_('Details (default)'), :details]].tap do |choices|
          choices << [_('Security dashboard'), :security_dashboard] if License.feature_available?(:security_dashboard)
        end
      end
    end

    def group_overview_content_preference?
      group_view_choices.size > 1
    end
  end
end
