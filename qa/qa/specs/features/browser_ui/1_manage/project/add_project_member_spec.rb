# frozen_string_literal: true

module QA
  context 'Manage' do
    describe 'Add project member' do
      it 'user adds project member' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        user = Factory::Resource::User.fabricate!

        project = Factory::Resource::Project.fabricate! do |resource|
          resource.name = 'add-member-project'
        end
        project.visit!

        Page::Project::Menu.perform(&:click_members_settings)
        Page::Project::Settings::Members.perform do |page|
          page.add_member(user.username)
        end

        expect(page).to have_content("#{user.name} @#{user.username} Given access")
      end
    end
  end
end
