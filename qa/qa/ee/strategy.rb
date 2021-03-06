module QA
  module EE
    module Strategy
      extend self

      def extend_autoloads!
        require 'qa/ee'
      end

      def perform_before_hooks
        return unless ENV['EE_LICENSE']

        EE::Scenario::License::Add.perform(ENV['EE_LICENSE'])
      rescue
        Capybara::Screenshot.screenshot_and_save_page
        raise
      end
    end
  end
end
