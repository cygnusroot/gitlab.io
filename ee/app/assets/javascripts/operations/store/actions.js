import Api from '~/api';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import { __, s__, n__, sprintf } from '~/locale';
import * as types from './mutation_types';
import _ from 'underscore';

const API_MINIMUM_QUERY_LENGTH = 3;

export const addProjectsToDashboard = ({ state, dispatch }) => {
  axios
    .post(state.projectEndpoints.add, {
      project_ids: state.selectedProjects.map(p => p.id),
    })
    .then(response => dispatch('requestAddProjectsToDashboardSuccess', response.data))
    .catch(() => dispatch('requestAddProjectsToDashboardError'));
};

export const toggleSelectedProject = ({ commit, state }, project) => {
  if (!_.findWhere(state.selectedProjects, { id: project.id })) {
    commit(types.ADD_SELECTED_PROJECT, project);
  } else {
    commit(types.REMOVE_SELECTED_PROJECT, project);
  }
};

export const clearSearchResults = ({ commit }) => {
  commit(types.CLEAR_SEARCH_RESULTS);
};

export const requestAddProjectsToDashboardSuccess = ({ dispatch, state }, data) => {
  const { added, invalid } = data;

  if (invalid.length) {
    const projectNames = state.selectedProjects.reduce((accumulator, project) => {
      if (invalid.includes(project.id)) {
        accumulator.push(project.name);
      }
      return accumulator;
    }, []);
    let invalidProjects;
    if (projectNames.length > 2) {
      invalidProjects = `${projectNames.slice(0, -1).join(', ')}, and ${projectNames.pop()}`;
    } else if (projectNames.length > 1) {
      invalidProjects = projectNames.join(' and ');
    } else {
      [invalidProjects] = projectNames;
    }
    createFlash(
      sprintf(
        s__(
          'OperationsDashboard|Unable to add %{invalidProjects}. The Operations Dashboard is available for public projects, and private projects in groups with a Gold plan.',
        ),
        { invalidProjects },
      ),
    );
  }

  if (added.length) {
    dispatch('fetchProjects');
  }
};

export const requestAddProjectsToDashboardError = ({ state }) => {
  createFlash(
    sprintf(__('Something went wrong, unable to add %{project} to dashboard'), {
      project: n__('project', 'projects', state.selectedProjects.length),
    }),
  );
};

export const fetchProjects = ({ state, dispatch }) => {
  dispatch('requestProjects');
  axios
    .get(state.projectEndpoints.list)
    .then(response => dispatch('receiveProjectsSuccess', response.data))
    .catch(() => dispatch('receiveProjectsError'))
    .then(() => dispatch('requestProjects'))
    .catch(() => {});
};

export const requestProjects = ({ commit }) => {
  commit(types.TOGGLE_IS_LOADING_PROJECTS);
};

export const receiveProjectsSuccess = ({ commit }, data) => {
  commit(types.SET_PROJECTS, data.projects);
};

export const receiveProjectsError = ({ commit }) => {
  commit(types.SET_PROJECTS, null);
  createFlash(__('Something went wrong, unable to get operations projects'));
};

export const removeProject = ({ dispatch }, removePath) => {
  axios
    .delete(removePath)
    .then(() => dispatch('requestRemoveProjectSuccess'))
    .catch(() => dispatch('requestRemoveProjectError'));
};

export const requestRemoveProjectSuccess = ({ dispatch }) => {
  dispatch('fetchProjects');
};

export const requestRemoveProjectError = () => {
  createFlash(__('Something went wrong, unable to remove project'));
};

export const setSearchQuery = ({ commit }, query) => {
  commit(types.SET_SEARCH_QUERY, query);
};

export const searchProjects = ({ commit, state }) => {
  if (!state.searchQuery) {
    commit(types.SEARCHED_WITH_NO_QUERY);
  } else if (state.searchQuery.length < API_MINIMUM_QUERY_LENGTH) {
    commit(types.SEARCHED_WITH_TOO_SHORT_QUERY);
  } else {
    commit(types.INCREMENT_PROJECT_SEARCH_COUNT, 1);

    // Flipping this property separately to allows the UI
    // to hide the "minimum query" message
    // before the seach results arrive from the API
    commit(types.SET_MESSAGE_MINIMUM_QUERY, false);

    Api.projects(state.searchQuery, {})
      .then(results => {
        if (results.length === 0) {
          commit(types.SEARCHED_SUCCESSFULLY_NO_RESULTS);
        } else {
          commit(types.SEARCHED_SUCCESSFULLY_WITH_RESULTS, results);
        }

        commit(types.DECREMENT_PROJECT_SEARCH_COUNT, 1);
      })
      .catch(() => {
        commit(types.SEARCHED_WITH_API_ERROR);
        commit(types.DECREMENT_PROJECT_SEARCH_COUNT, 1);
      });
  }
};

export const setProjectEndpoints = ({ commit }, endpoints) => {
  commit(types.SET_PROJECT_ENDPOINT_LIST, endpoints.list);
  commit(types.SET_PROJECT_ENDPOINT_ADD, endpoints.add);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
