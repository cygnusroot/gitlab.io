import { __ } from '~/locale';
import createFlash from '~/flash';
import SCIMTokenService from './scim_token_service';

export default class SCIMTokenToggleArea {
  constructor(generateSelector, formSelector, groupPath) {
    this.generateContainer = document.querySelector(generateSelector);
    this.formContainer = document.querySelector(formSelector);
    this.scimLoadingSpinner = document.querySelector('.js-scim-loading-container');

    this.generateButton = this.generateContainer.querySelector('.js-generate-scim-token');
    this.resetButton = this.formContainer.querySelector('.js-reset-scim-token');
    this.scimTokenInput = this.formContainer.querySelector('#scim_token');

    this.generateButton.addEventListener('click', () => this.generateSCIMToken());
    this.resetButton.addEventListener('click', () => this.resetSCIMToken());

    this.service = new SCIMTokenService(groupPath);
  }

  setSCIMTokenValue(value) {
    this.scimTokenInput.value = value;
  }

  toggleSCIMTokenHelperText() {
    this.formContainer.querySelector('.input-group-append').classList.toggle('d-none'); // Shows the clipboard icon
    this.formContainer.querySelector('.form-text span:first-of-type').classList.toggle('d-none');
    this.formContainer.querySelector('.form-text span:last-of-type').classList.toggle('d-none');
  }

  // eslint-disable-next-line class-methods-use-this
  toggleFormVisibility(form) {
    form.classList.toggle('d-none');
  }

  setSCIMTokenFormTitle(title) {
    this.formContainer.querySelector('label:first-of-type').innerHTML = title;
  }

  toggleSCIMLoading() {
    this.scimLoadingSpinner.classList.toggle('d-none');
  }

  setTokenAndToggleSCIMForm(value) {
    this.setSCIMTokenValue(value);
    this.setSCIMTokenFormTitle(__('Your new SCIM token'));
    this.toggleSCIMTokenHelperText();
    this.toggleSCIMLoading();
    this.toggleFormVisibility(this.formContainer);
  }

  generateSCIMToken() {
    this.toggleFormVisibility(this.generateContainer);
    this.toggleSCIMLoading();

    this.service
      .generateNewSCIMToken()
      .then(response => {
        this.setTokenAndToggleSCIMForm(response.data.scim_token);
      })
      .catch(error => {
        createFlash(error);
        this.toggleSCIMLoading();
        this.toggleFormVisibility(this.generateContainer);
      });
  }

  resetSCIMToken() {
    if (
      // eslint-disable-next-line no-alert
      window.confirm(
        __(
          'Are you sure you want to reset the SCIM token? SCIM provisioning will stop working until the new token is updated.',
        ),
      )
    ) {
      this.toggleFormVisibility(this.formContainer);
      this.toggleSCIMLoading();

      this.service
        .generateNewSCIMToken()
        .then(response => {
          this.setTokenAndToggleSCIMForm(response.data.scim_token);
        })
        .catch(error => {
          createFlash(error);
          this.toggleSCIMLoading();
          this.toggleFormVisibility(this.formContainer);
        });
    }
  }
}
