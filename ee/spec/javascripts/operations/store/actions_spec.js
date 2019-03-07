import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import store from 'ee/operations/store/index';
import * as types from 'ee/operations/store/mutation_types';
import defaultActions, * as actions from 'ee/operations/store/actions';
import testAction from 'spec/helpers/vuex_action_helper';
import { clearState } from '../helpers';
import { mockText, mockProjectData } from '../mock_data';

describe('actions', () => {
  const mockAddEndpoint = 'mock-add_endpoint';
  const mockListEndpoint = 'mock-list_endpoint';
  const mockResponse = { data: 'mock-data' };
  const mockProjects = mockProjectData(1);
  const [mockOneProject] = mockProjects;
  let mockAxios;

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    clearState(store);
    mockAxios.restore();
  });

  describe('addProjectsToDashboard', () => {
    it('posts selected project ids to project add endpoint', done => {
      store.state.projectEndpoints.add = mockAddEndpoint;
      store.state.selectedProjects = mockProjects;

      mockAxios.onPost(mockAddEndpoint).replyOnce(200, mockResponse);

      testAction(
        actions.addProjectsToDashboard,
        null,
        store.state,
        [],
        [
          {
            type: 'requestAddProjectsToDashboardSuccess',
            payload: mockResponse,
          },
        ],
        done,
      );
    });

    it('calls addProjectsToDashboard error handler on error', done => {
      mockAxios.onPost(mockAddEndpoint).replyOnce(500);

      testAction(
        actions.addProjectsToDashboard,
        null,
        store.state,
        [],
        [{ type: 'requestAddProjectsToDashboardError' }],
        done,
      );
    });
  });

  describe('toggleSelectedProject', () => {
    it(`adds a project to selectedProjects if it doesn't already exist in the list`, done => {
      testAction(
        actions.toggleSelectedProject,
        mockOneProject,
        store.state,
        [
          {
            type: types.ADD_SELECTED_PROJECT,
            payload: mockOneProject,
          },
        ],
        [],
        done,
      );
    });

    it(`removes a project from selectedProjects if it already exist in the list`, done => {
      store.state.selectedProjects = mockProjects;

      testAction(
        actions.toggleSelectedProject,
        mockOneProject,
        store.state,
        [
          {
            type: types.REMOVE_SELECTED_PROJECT,
            payload: mockOneProject,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('requestAddProjectsToDashboardSuccess', () => {
    it('fetches projects when new projects are added to the dashboard', done => {
      testAction(
        actions.requestAddProjectsToDashboardSuccess,
        {
          added: [1],
          invalid: [],
          duplicate: [],
        },
        store.state,
        [],
        [
          {
            type: 'fetchProjects',
          },
        ],
        done,
      );
    });

    const errorMessage =
      'The Operations Dashboard is available for public projects, and private projects in groups with a Gold plan.';
    const selectProjects = count => {
      for (let i = 0; i < count; i += 1) {
        store.dispatch('toggleSelectedProject', {
          id: i,
          name: 'mock-name',
        });
      }
    };
    const addInvalidProjects = invalid =>
      store.dispatch('requestAddProjectsToDashboardSuccess', {
        added: [],
        invalid,
        duplicate: [],
      });

    it('displays an error when user tries to add one invalid project to dashboard', () => {
      const spy = spyOnDependency(defaultActions, 'createFlash');
      selectProjects(1);
      addInvalidProjects([0]);

      expect(spy).toHaveBeenCalledWith(`Unable to add mock-name. ${errorMessage}`);
    });

    it('displays an error when user tries to add two invalid projects to dashboard', () => {
      const spy = spyOnDependency(defaultActions, 'createFlash');
      selectProjects(2);
      addInvalidProjects([0, 1]);

      expect(spy).toHaveBeenCalledWith(`Unable to add mock-name and mock-name. ${errorMessage}`);
    });

    it('displays an error when user tries to add more than two invalid projects to dashboard', () => {
      const spy = spyOnDependency(defaultActions, 'createFlash');
      selectProjects(3);
      addInvalidProjects([0, 1, 2]);

      expect(spy).toHaveBeenCalledWith(
        `Unable to add mock-name, mock-name, and mock-name. ${errorMessage}`,
      );
    });
  });

  describe('requestAddProjectsToDashboardError', () => {
    it('shows error message', () => {
      const spy = spyOnDependency(defaultActions, 'createFlash');
      store.dispatch('requestAddProjectsToDashboardError');

      expect(spy).toHaveBeenCalledWith(mockText.ADD_PROJECTS_ERROR);
    });
  });

  describe('clearSearchResults', () => {
    it('clears all project search results', done => {
      store.state.projectSearchResults = mockProjects;

      testAction(
        actions.clearSearchResults,
        null,
        store.state,
        [
          {
            type: types.CLEAR_SEARCH_RESULTS,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchProjects', () => {
    it('calls project list endpoint', done => {
      store.state.projectEndpoints.list = mockListEndpoint;
      mockAxios.onGet(mockListEndpoint).replyOnce(200);

      testAction(
        actions.fetchProjects,
        null,
        store.state,
        [],
        [
          { type: 'requestProjects' },
          { type: 'receiveProjectsSuccess' },
          { type: 'requestProjects' },
        ],
        done,
      );
    });

    it('handles response errors', done => {
      store.state.projectEndpoints.list = mockListEndpoint;
      mockAxios.onGet(mockListEndpoint).replyOnce(500);

      testAction(
        actions.fetchProjects,
        null,
        store.state,
        [],
        [
          { type: 'requestProjects' },
          { type: 'receiveProjectsError' },
          { type: 'requestProjects' },
        ],
        done,
      );
    });
  });

  describe('requestProjects', () => {
    it('toggles project loading state', done => {
      testAction(
        actions.requestProjects,
        null,
        store.state,
        [{ type: types.TOGGLE_IS_LOADING_PROJECTS }],
        [],
        done,
      );
    });
  });

  describe('receiveProjectsSuccess', () => {
    it('sets projects from data on success', done => {
      testAction(
        actions.receiveProjectsSuccess,
        { projects: mockProjects },
        store.state,
        [
          {
            type: types.SET_PROJECTS,
            payload: mockProjects,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveProjectsError', () => {
    it('clears projects and alerts user of error', done => {
      const spy = spyOnDependency(defaultActions, 'createFlash');
      store.state.projects = mockProjects;

      testAction(
        actions.receiveProjectsError,
        null,
        store.state,
        [
          {
            type: types.SET_PROJECTS,
            payload: null,
          },
        ],
        [],
        done,
      );

      expect(spy).toHaveBeenCalledWith(mockText.RECEIVE_PROJECTS_ERROR);
    });
  });

  describe('removeProject', () => {
    const mockRemovePath = 'mock-removePath';

    it('calls project removal path and fetches projects on success', done => {
      mockAxios.onDelete(mockRemovePath).replyOnce(200);

      testAction(
        actions.removeProject,
        mockRemovePath,
        null,
        [],
        [{ type: 'requestRemoveProjectSuccess' }],
        done,
      );
    });

    it('passes off handling of project removal errors', done => {
      mockAxios.onDelete(mockRemovePath).replyOnce(500);

      testAction(
        actions.removeProject,
        mockRemovePath,
        null,
        [],
        [{ type: 'requestRemoveProjectError' }],
        done,
      );
    });
  });

  describe('requestRemoveProjectSuccess', () => {
    it('fetches operations dashboard projects', done => {
      testAction(
        actions.requestRemoveProjectSuccess,
        null,
        null,
        [],
        [{ type: 'fetchProjects' }],
        done,
      );
    });
  });

  describe('requestRemoveProjectError', () => {
    it('displays project removal error', done => {
      const spy = spyOnDependency(defaultActions, 'createFlash');

      testAction(actions.requestRemoveProjectError, null, null, [], [], done);

      expect(spy).toHaveBeenCalledWith(mockText.REMOVE_PROJECT_ERROR);
    });
  });

  describe('searchProjects', () => {
    const mockQuery = 'mock-query';

    it('commits the SEARCHED_WITH_NO_QUERY if the search query was empty', done => {
      mockAxios.onAny().replyOnce(200, mockProjects);
      store.state.searchQuery = '';

      testAction(
        actions.searchProjects,
        mockQuery,
        store.state,
        [
          {
            type: types.SEARCHED_WITH_NO_QUERY,
          },
        ],
        [],
        done,
      );
    });

    it('sets project search results', done => {
      mockAxios.onAny().replyOnce(200, mockProjects);
      store.state.searchQuery = mockQuery;

      testAction(
        actions.searchProjects,
        mockQuery,
        store.state,
        [
          {
            type: types.INCREMENT_PROJECT_SEARCH_COUNT,
            payload: 1,
          },
          {
            type: types.SET_MESSAGE_MINIMUM_QUERY,
            payload: false,
          },
          {
            type: types.SEARCHED_SUCCESSFULLY_WITH_RESULTS,
            payload: mockProjects,
          },
          {
            type: types.DECREMENT_PROJECT_SEARCH_COUNT,
            payload: 1,
          },
        ],
        [],
        done,
      );
    });

    it(`commits the SEARCHED_WITH_TOO_SHORT_QUERY type if the search query wasn't long enough`, done => {
      mockAxios.onAny().replyOnce(200, []);
      store.state.searchQuery = 'a';

      testAction(
        actions.searchProjects,
        mockQuery,
        store.state,
        [
          {
            type: types.SEARCHED_WITH_TOO_SHORT_QUERY,
          },
        ],
        [],
        done,
      );
    });

    it('commits the SEARCHED_SUCCESSFULLY_NO_RESULTS type (among others) if the search returns with no results', done => {
      mockAxios.onAny().replyOnce(200, []);
      store.state.searchQuery = mockQuery;

      testAction(
        actions.searchProjects,
        mockQuery,
        store.state,
        [
          {
            type: types.INCREMENT_PROJECT_SEARCH_COUNT,
            payload: 1,
          },
          {
            type: types.SET_MESSAGE_MINIMUM_QUERY,
            payload: false,
          },
          {
            type: types.SEARCHED_SUCCESSFULLY_NO_RESULTS,
          },
          {
            type: types.DECREMENT_PROJECT_SEARCH_COUNT,
            payload: 1,
          },
        ],
        [],
        done,
      );
    });

    it('commits the SEARCHED_WITH_API_ERROR type (among others) if the search API returns an error code', done => {
      store.state.searchQuery = mockQuery;
      mockAxios.onAny().replyOnce(500);

      testAction(
        actions.searchProjects,
        mockQuery,
        store.state,
        [
          {
            type: types.INCREMENT_PROJECT_SEARCH_COUNT,
            payload: 1,
          },
          {
            type: types.SET_MESSAGE_MINIMUM_QUERY,
            payload: false,
          },
          {
            type: types.SEARCHED_WITH_API_ERROR,
          },
          {
            type: types.DECREMENT_PROJECT_SEARCH_COUNT,
            payload: 1,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setProjectEndpoints', () => {
    it('commits project list and add endpoints', done => {
      testAction(
        actions.setProjectEndpoints,
        {
          add: mockAddEndpoint,
          list: mockListEndpoint,
        },
        store.state,
        [
          {
            type: types.SET_PROJECT_ENDPOINT_LIST,
            payload: mockListEndpoint,
          },
          {
            type: types.SET_PROJECT_ENDPOINT_ADD,
            payload: mockAddEndpoint,
          },
        ],
        [],
        done,
      );
    });
  });
});
