import React from 'react';
import thunk from 'redux-thunk';
import { shallow } from 'enzyme';
import toJson from 'enzyme-to-json';
import configureMockStore from 'redux-mock-store';
import RepositorySetRepositories from '../RepositorySetRepositories';


const mockStore = configureMockStore([thunk]);
const store = mockStore({data: {} });

describe('RepositorySetRepositories Component', () => {
  let shallowWrapper;
  beforeEach(() => {
    shallowWrapper = shallow(<RepositorySetRepositories
      store={store}
      contentId={1}
      productId={1}
      label="some label"
      type="foo"
    />);
  });

  afterEach(() => {
    store.clearActions();
  });

  it('sorts repos correctly', async () => {
    const sortedRepos = [
      { arch: 'x86_64', releasever: '5.11' }
    ]

    const result = shallowWrapper.instance().sortedRepos(sortedRepos);
    sortedRepos.forEach((repo, i) => {
      expect(result[i]).toEqual(sortedRepos[i]);
    });
  });
});
