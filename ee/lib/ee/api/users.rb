# frozen_string_literal: true

module EE
  module API
    module Users
      extend ActiveSupport::Concern

      prepended do
        helpers do
          params :optional_attributes_ee do
            optional :shared_runners_minutes_limit, type: Integer, desc: '(admin-only) Pipeline minutes quota for this user'
            optional :extra_shared_runners_minutes_limit, type: Integer, desc: '(admin-only) Extra pipeline minutes quota for this user'
          end
        end
      end
    end
  end
end
