import SidebarStore from '~/sidebar/stores/sidebar_store';
import Mock from './mock_data';

describe('Sidebar store', () => {
  const assignee = {
    id: 2,
    name: 'gitlab user 2',
    username: 'gitlab2',
    avatar_url: 'http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
  };

  const anotherAssignee = {
    id: 3,
    name: 'gitlab user 3',
    username: 'gitlab3',
    avatar_url: 'http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
  };

  beforeEach(() => {
    this.store = new SidebarStore({
      currentUser: {
        id: 1,
        name: 'Administrator',
        username: 'root',
        avatar_url: 'http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
      },
      editable: true,
      rootPath: '/',
      endpoint: '/gitlab-org/gitlab-shell/issues/5.json',
    });
  });

  it('adds a new assignee', () => {
    this.store.addAssignee(assignee);
    expect(this.store.assignees.length).toEqual(1);
  });

  it('removes an assignee', () => {
    this.store.removeAssignee(assignee);
    expect(this.store.assignees.length).toEqual(0);
  });

  it('finds an existent assignee', () => {
    let foundAssignee;

    this.store.addAssignee(assignee);
    foundAssignee = this.store.findAssignee(assignee);
    expect(foundAssignee).toBeDefined();
    expect(foundAssignee).toEqual(assignee);
    foundAssignee = this.store.findAssignee(anotherAssignee);
    expect(foundAssignee).toBeUndefined();
  });

  it('removes all assignees', () => {
    this.store.removeAllAssignees();
    expect(this.store.assignees.length).toEqual(0);
  });

  it('process assigned data', () => {
    const users = {
      assignees: Mock.createNumberRandomUsers(3),
    };

    this.store.processAssigneeData(users);
    expect(this.store.assignees.length).toEqual(3);
  });

  it('process time tracking data', () => {
    this.store.processTimeTrackingData(Mock.time);
    expect(this.store.timeEstimate).toEqual(Mock.time.time_estimate);
    expect(this.store.totalTimeSpent).toEqual(Mock.time.total_time_spent);
    expect(this.store.humanTimeEstimate).toEqual(Mock.time.human_time_estimate);
    expect(this.store.humanTotalTimeSpent).toEqual(Mock.time.human_total_time_spent);
  });
});
