# frozen_string_literal: true

module EE
  module Search
    module GroupService
      extend ::Gitlab::Utils::Override

      override :use_elasticsearch?
      def use_elasticsearch?
        return false unless group

        group.use_elasticsearch?
      end

      override :elastic_projects
      def elastic_projects
        @elastic_projects ||= projects.pluck(:id) # rubocop:disable CodeReuse/ActiveRecord
      end

      override :elastic_global
      def elastic_global
        false
      end
    end
  end
end
