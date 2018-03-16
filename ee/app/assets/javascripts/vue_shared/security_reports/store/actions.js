import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';

export const setAppType = ({ commit }, type) =>
  commit(types.SET_APP_TYPE, type);

export const setHeadBlobPath = ({ commit }, blobPath) =>
  commit(types.SET_HEAD_BLOB_PATH, blobPath);

export const setBaseBlobPath = ({ commit }, blobPath) =>
  commit(types.SET_BASE_BLOB_PATH, blobPath);

/**
 * SAST
 */
export const setSastHeadPath = ({ commit }, path) =>
  commit(types.SET_SAST_HEAD_PATH, path);

export const setSastBasePath = ({ commit }, path) =>
  commit(types.SET_SAST_BASE_PATH, path);

export const requestSastReports = ({ commit }) =>
  commit(types.REQUEST_SAST_REPORTS);

export const receiveSastReports = ({ commit }, response) =>
  commit(types.RECEIVE_SAST_REPORTS, response);

export const receiveSastError = ({ commit }, error) =>
  commit(types.RECEIVE_SAST_REPORTS, error);

export const fetchSastReports = ({ state, dispatch }) => {
  const base = state.sast.paths.base;
  const head = state.sast.paths.head;

  dispatch('requestSastReports');

  if (head && base) {
    Promise.all([
      axios.get(head),
      axios.get(base),
    ])
    .then((values) => {
      dispatch('receiveSastReports', {
        head: values[0].data,
        base: values[1].data,
      });
    })
    .catch(() => {
      dispatch('receiveSastError');
    });
  } else {
    axios.get(head)
      .then((response) => {
        dispatch('receiveSastReports', {
          head: response.data,
        });
      })
      .catch(() => {
        dispatch('receiveSastError');
      });
  }
};

/**
 * SAST CONTAINER
 */
export const setSastContainerHeadPath = ({ commit }, path) =>
  commit(types.SET_SAST_CONTAINER_HEAD_PATH, path);

export const setSastContainerBasePath = ({ commit }, path) =>
  commit(types.SET_SAST_CONTAINER_BASE_PATH, path);

export const requestSastContainerReports = ({ commit }) =>
  commit(types.REQUEST_SAST_CONTAINER_REPORTS);

export const receiveSastContainerReports = ({ commit }, response) =>
  commit(types.RECEIVE_SAST_CONTAINER_REPORTS, response);

export const receiveSastContainerError = ({ commit }, error) =>
  commit(types.RECEIVE_SAST_CONTAINER_ERROR, error);

export const fetchSastContainerReports = ({ state, dispatch }) => {
  const base = state.sastContainer.paths.base;
  const head = state.sastContainer.paths.head;

  dispatch('requestSastContainerReports');

  if (head && base) {
    Promise.all([
      axios.get(head),
      axios.get(base),
    ])
    .then((values) => {
      dispatch('receiveSastContainerReports', {
        head: values[0].data,
        base: values[1].data,
      });
    })
    .catch(() => {
      dispatch('receiveSastContainerError');
    });
  } else {
    axios.get(head)
      .then((response) => {
        dispatch('receiveSastContainerReports', {
          head: response.data,
        });
      })
      .catch(() => {
        dispatch('receiveSastContainerError');
      });
  }
};

/**
 * DAST
 */
export const setDastHeadPath = ({ commit }, path) =>
  commit(types.SET_DAST_HEAD_PATH, path);

export const setDastBasePath = ({ commit }, path) =>
  commit(types.SET_DAST_BASE_PATH, path);

export const requestDastReports = ({ commit }) =>
  commit(types.REQUEST_DAST_REPORTS);

export const receiveDastReports = ({ commit }, response) =>
  commit(types.RECEIVE_DAST_REPORTS, response);

export const receiveDastError = ({ commit }, error) =>
  commit(types.RECEIVE_DAST_ERROR, error);

export const fetchDastReports = ({ state, dispatch }) => {
  const base = state.sastContainer.paths.base;
  const head = state.sastContainer.paths.head;

  dispatch('requestDastReports');

  if (head && base) {
    Promise.all([
      axios.get(head),
      axios.get(base),
    ])
    .then((values) => {
      dispatch('receiveDastReports', {
        head: values[0].data,
        base: values[1].data,
      });
    })
    .catch(() => {
      dispatch('receiveDastError');
    });
  } else {
    axios.get(head)
      .then((response) => {
        dispatch('receiveDastReports', {
          head: response.data,
        });
      })
      .catch(() => {
        dispatch('receiveDastError');
      });
  }
};
