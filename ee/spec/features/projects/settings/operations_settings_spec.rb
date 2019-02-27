# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Settings' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:role) { :maintainer }
  let(:create_issue) { 'Create an issue. Issues are created for each alert triggered.' }
  let(:send_email) { 'Send an email notification to Developers.' }
  let(:issue_template_1) { 'Feature:\nReason:' }
  let(:issue_template_2) { 'Bug Description:\nExpected behavior:\n' }

  before do
    sign_in(user)
    project.add_role(user, role)
  end

  # test
  # licensed shows section
  describe 'Incidents' do
    context 'with license' do
      before do
        # stub_licensed_features(incident_alerts: true)
        visit project_settings_operations_path(project)
      end

      it 'renders form for incident management' do
        expect(page).to have_selector('h4', text: 'Incidents')
      end

      it 'sets correct default values' do
        expect(find_field(create_issue)).not_to be_checked
        expect(find_field(send_email)).to be_checked
      end

      it 'updates form values' do
        check(create_issue)
        template_select = find('select[name="project[issue_template_key]"]')
        template_select.find(:xpath, 'option[1]').select_option
        check(send_email)
        save_form

        expect(find_field(create_issue)).to be_checked
        expect(template_select.selected).to eq(issue_template_2)
        expect(find_field(send_email)).not_to be_checked
      end

      # it 'updates issue template' do
      #   save_form
      # end

      # it 'updates email notification' do
      #   save_form
      # end

      def save_form
        page.within "#incident_management_edit_project_#{project.id}" do
          click_on 'Save changes'
        end
      end
    end

    context 'without license' do
      before do
        # stub_licensed_features(incident_alerts: false)
        visit project_settings_operations_path(project)
      end

      it 'renders form for incident management' do
        expect(page).not_to have_selector('h4', text: 'Incidents')
      end
    end
  end
end