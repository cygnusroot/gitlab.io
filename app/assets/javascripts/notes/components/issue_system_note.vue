<script>
  import { mapGetters } from 'vuex';
  import iconsMap from './issue_note_icons';
  import issueNoteHeader from './issue_note_header.vue';

  export default {
    name: 'systemNote',
    props: {
      note: {
        type: Object,
        required: true,
      },
    },
    components: {
      issueNoteHeader,
    },
    computed: {
      ...mapGetters([
        'targetNoteHash',
      ]),
      noteAnchorId() {
        return `note_${this.note.id}`;
      },
      isTargetNote() {
        return this.targetNoteHash === this.noteAnchorId;
      },
    },
    created() {
      this.svg = iconsMap[this.note.system_note_icon_name];
    },
  };
</script>

<template>
  <li
    :id="noteAnchorId"
    :class="{ target: isTargetNote }"
    class="note system-note timeline-entry">
    <div class="timeline-entry-inner">
      <div
        class="timeline-icon"
        v-html="svg">
      </div>
      <div class="timeline-content">
        <div class="note-header">
          <issue-note-header
            :author="note.author"
            :created-at="note.created_at"
            :note-id="note.id"
            :action-text-html="note.note_html" />
        </div>
      </div>
    </div>
  </li>
</template>
