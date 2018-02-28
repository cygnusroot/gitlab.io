module Projects
  class SetupCiCd < BaseService
    include ::TriggersHelper

    def execute
      update_project
      disable_project_features
      create_webhook
    end

    private

    def update_project
      project.update_attributes!(
        container_registry_enabled:          false,
        mirror:                              true,
        mirror_trigger_builds:               true,
        mirror_overwrites_diverged_branches: true,
        only_mirror_protected_branches:      false,
        mirror_user_id:                      current_user.id
      )
    end

    def disable_project_features
      project.project_feature.update_attributes!(
        issues_access_level:         ProjectFeature::DISABLED,
        merge_requests_access_level: ProjectFeature::DISABLED,
        wiki_access_level:           ProjectFeature::DISABLED,
        snippets_access_level:       ProjectFeature::DISABLED
      )
    end

    def create_webhook
      CreateExternalWebhookWorker.perform_async(project.id)
    end
  end
end
