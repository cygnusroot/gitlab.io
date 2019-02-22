require 'spec_helper'

describe 'SCIM Token handling', :js do
  let(:user) { create(:user) }
  let(:group) { create(:group) }

  before do
    group.add_owner(user)
    stub_licensed_features(group_saml: true)
  end

  describe 'group has no existing scim token' do
    before do
      sign_in(user)
      visit group_saml_providers_path(group)
    end

    it 'displays generate token form and hides scim form' do
      expect(page).to have_selector('.js-generate-scim-token-container', visible: true)
      expect(page).to have_selector('.js-scim-token-container', visible: false)
    end

    describe 'generate token form' do
      it 'displays the title and generate button' do
        page.within '.js-generate-scim-token-container' do
          expect(page).to have_content('Generate a SCIM token to set up your Syetem for Cross-Domain Identity Management.')
          expect(page).to have_button('Generate a SCIM token')
        end
      end

      it 'hides the generate token form and displays the scim token information' do
        click_button('Generate a SCIM token')

        expect(page).to have_selector('.js-generate-scim-token-container', visible: false)
        expect(page).to have_selector('.js-scim-token-container', visible: true)

        page.within '.js-scim-token-container' do
          expect(page.find('#scim_token').value).to eq('foobar') # this will need to update
          expect(page.find('#scim_endpoint_url').value).to eq('https://gitlab.com/group-name/api/scim/v2/groups/manage') # this will need to update
        end
      end
    end
  end

  # Commented out until this is setup in HAML
  # Need to add create token for group in before
  #
  # describe 'group has existing scim token' do
  #   before do
  #     sign_in(user)
  #     visit group_saml_providers_path(group)
  #   end

  #   it 'displays scim form and hides generate token form' do
  #     expect(page).to have_selector('.js-generate-scim-token-container', visible: false)
  #     expect(page).to have_selector('.js-scim-token-container', visible: true)
  #   end

  #   describe 'scim token form' do
  #     it 'displays the endpoint url + reset button and hides the scim token' do

  #       page.within '.js-scim-token-container' do
  #         expect(page).to have_button('reset it.')
  #         expect(page.find('#scim_token').value).to eq('********************')
  #         expect(page.find('#scim_endpoint_url').value).to eq('https://gitlab.com/group-name/api/scim/v2/groups/manage') # this will need to update
  #       end
  #     end

  #     describe 'reset the scim token' do

  #       it 'does not reset the token if you canel the reset' do

  #         page.dismiss_confirm do
  #           click_button('reset it.')
  #         end

  #         page.within '.js-scim-token-container' do
  #           expect(page.find('#scim_token').value).to eq('********************')
  #         end
  #       end

  #       it 'resets the token upon confirmation' do

  #         page.accept_confirm do
  #           click_button('reset it.')
  #         end

  #         page.within '.js-scim-token-container' do
  #           expect(page.find('#scim_token').value).to eq('foobar')
  #         end
  #       end
  #     end
  #   end
  # end
end
