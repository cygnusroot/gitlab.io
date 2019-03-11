# frozen_string_literal: true

module EE
  module API
    module Groups
      extend ActiveSupport::Concern

      prepended do
        helpers do
          params :optional_params_ee do
            optional :membership_lock, type: Grape::API::Boolean, desc: 'Prevent adding new members to project membership within this group'
            optional :ldap_cn, type: String, desc: 'LDAP Common Name'
            optional :ldap_access, type: Integer, desc: 'A valid access level'
            optional :shared_runners_minutes_limit, type: Integer, desc: '(admin-only) Pipeline minutes quota for this group'
            optional :extra_shared_runners_minutes_limit, type: Integer, desc: '(admin-only) Extra pipeline minutes quota for this group'
            all_or_none_of :ldap_cn, :ldap_access
          end

          def require_admin_on_create
            authenticated_as_admin! if params.values_at(:shared_runners_minutes_limit, :extra_shared_runners_minutes_limit).any?
          end
        end

        params do
          requires :id, type: String, desc: 'The ID of a group'
        end
        resource :groups, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          desc 'Update a group. Available only for users who can administrate groups.' do
            success ::API::Entities::Group
          end
          params do
            optional :name, type: String, desc: 'The name of the group'
            optional :path, type: String, desc: 'The path of the group'
            optional :file_template_project_id, type: Integer, desc: 'The ID of a project to use for custom templates in this group'

            use :optional_params
          end
          put ':id' do
            group = find_group!(params[:id])
            authorize! :admin_group, group

            group.shared_runners_minutes_limit = params[:shared_runners_minutes_limit] if params[:shared_runners_minutes_limit].present?
            group.extra_shared_runners_minutes_limit = params[:extra_shared_runners_minutes_limit] if params[:extra_shared_runners_minutes_limit].present?

            if group.changed?
              authenticated_as_admin!
            end

            params.delete(:file_template_project_id) unless
              group.feature_available?(:custom_file_templates_for_namespace)

            if ::Groups::UpdateService.new(group, current_user, declared_params(include_missing: false)).execute
              present group, with: ::API::Entities::GroupDetail, current_user: current_user
            else
              render_validation_error!(group)
            end
          end
        end
      end
    end
  end
end
