import axios from '../../../../../../app/assets/javascripts/lib/utils/axios_utils';

export default class FeatureFlagsService {
  /**
   * Endpoint URL for the feature flags
   *
   * @param  {String} root
   */
  constructor(endpoint) {
    this.endpoint = endpoint;
  }

  getFeatureFlags(data = {}) {
    const { CancelToken } = axios;

    this.cancelationSource = CancelToken.source();

    return axios.get(this.endpoint, {
      params: data,
      cancelToken: this.cancelationSource.token,
    });
  }

  // Using this to stub out some extra response data
  // eslint-disable-next-line class-methods-use-this
  temporary(resp, params) {
    let { features } = resp.data;
    if (params.scope === 'enabled') {
      features = features.filter(feature => feature.enabled);
    } else if (params.scope === 'disabled') {
      features = features.filter(feature => !feature.enabled);
    }
    return {
      ...resp,
      data: {
        ...resp.data,
        features: features.map(feature => ({
          ...feature,
          editUrl: `feature_flags/${feature.id}/edit`,
          deleteUrl: `feature_flags/${feature.id}`,
        })),
        count: {
          all: '26',
          enabled: '7',
          disabled: '19',
        },
      },
      headers: {
        ...resp.headers,
        'x-next-page': '',
        'x-page': '1',
        'x-per-page': '30',
        'x-prev-page': '',
        'x-total': '26',
        'x-total-pages': '1',
      },
    };
  }
}
