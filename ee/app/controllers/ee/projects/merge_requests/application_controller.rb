module EE
  module Projects
    module MergeRequests
      module ApplicationController
        extend ActiveSupport::Concern

        private

        def set_suggested_approvers
          if @merge_request.requires_approve?
            @suggested_approvers = ::Gitlab::AuthorityAnalyzer.new(
              @merge_request,
              @merge_request.author || current_user
            ).calculate(@merge_request.approvals_required)
          end
        end

        def merge_request_params
          clamp_approvals_before_merge(super)
        end

        def merge_request_params_attributes
          attrs = super.push(
            :approvals_before_merge,
            :approver_group_ids,
            :approver_ids
          )
          attrs << :squash if project.feature_available?(:merge_request_squash)

          attrs
        end

        # If the number of approvals is not greater than the project default, set to
        # nil, so that we fall back to the project default. If it's not set, we can
        # let the normal update logic handle this.
        def clamp_approvals_before_merge(mr_params)
          return mr_params unless mr_params[:approvals_before_merge]

          target_project = @project.forked_from_project if @project.id.to_s != mr_params[:target_project_id]
          target_project ||= @project

          if mr_params[:approvals_before_merge].to_i <= target_project.approvals_before_merge
            mr_params[:approvals_before_merge] = nil
          end

          mr_params
        end
      end
    end
  end
end
