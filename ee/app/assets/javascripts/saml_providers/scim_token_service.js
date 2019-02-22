import axios from '~/lib/utils/axios_utils';

export default class SCIMTokenService {
  constructor(groupPath) {
    this.axios = axios.create({
      baseURL: groupPath,
    });
  }

  // eslint-disable-next-line class-methods-use-this
  generateNewSCIMToken() {
    // return this.axios
    //   .post(`/-/scim_oauth`)

    return new Promise(resolve => {
      setTimeout(() => {
        resolve({
          data: {
            scim_token: 'foobar',
            scim_api_url: 'barfoo',
          },
        });
      }, 1000);
    });
  }
}
