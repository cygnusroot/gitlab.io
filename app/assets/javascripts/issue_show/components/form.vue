<script>
  import lockedWarning from './locked_warning.vue';
  import titleField from './fields/title.vue';
  import descriptionField from './fields/description.vue';
  import editActions from './edit_actions.vue';
  import descriptionTemplate from './fields/description_template.vue';

  export default {
    props: {
      canDestroy: {
        type: Boolean,
        required: true,
      },
      formState: {
        type: Object,
        required: true,
      },
      issuableTemplates: {
        type: Array,
        required: false,
        default: () => [],
      },
      markdownPreviewPath: {
        type: String,
        required: true,
      },
      markdownDocsPath: {
        type: String,
        required: true,
      },
      projectPath: {
        type: String,
        required: true,
      },
      projectNamespace: {
        type: String,
        required: true,
      },
    },
    components: {
      lockedWarning,
      titleField,
      descriptionField,
      descriptionTemplate,
      editActions,
    },
    computed: {
      hasIssuableTemplates() {
        return this.issuableTemplates.length;
      },
    },
  };
</script>

<template>
  <form>
    <locked-warning v-if="formState.lockedWarningVisible" />
    <div class="row">
      <div
        class="col-sm-4 col-lg-3"
        v-if="hasIssuableTemplates">
        <description-template
          :form-state="formState"
          :issuable-templates="issuableTemplates"
          :project-path="projectPath"
          :project-namespace="projectNamespace" />
      </div>
      <div
        :class="{
          'col-sm-8 col-lg-9': hasIssuableTemplates,
          'col-xs-12': !hasIssuableTemplates,
        }">
        <title-field
          :form-state="formState"
          :issuable-templates="issuableTemplates" />
      </div>
    </div>
    <description-field
      :form-state="formState"
      :markdown-preview-path="markdownPreviewPath"
      :markdown-docs-path="markdownDocsPath" />
    <edit-actions
      :form-state="formState"
      :can-destroy="canDestroy" />
  </form>
</template>
