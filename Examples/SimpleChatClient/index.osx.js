/* @flow */
'use strict';

import React from 'react-native-desktop';
import { createStore, applyMiddleware } from 'redux';
import { Provider } from 'react-redux/native';
import logger from 'redux-logger';
import thunk from 'redux-thunk';
import storage from 'redux-storage';
import createEngine from 'redux-storage/engines/reactNativeAsyncStorage';

import reducer from './reducers';
import { SIGNIN_REQUEST, SIGNIN_FAILURE } from './actions';
import App from './components/App';

const engine = createEngine('chat');
const wrappedReducer = storage.reducer(reducer);
const storageMiddleware = storage.createMiddleware(engine, [ SIGNIN_REQUEST, SIGNIN_FAILURE ]);

const middleware = process.env.NODE_ENV === 'production' ?
  [ thunk, storageMiddleware ] :
  [ thunk, logger(), storageMiddleware ];

const createStoreWithMiddleware = applyMiddleware(...middleware)(createStore);
const store = createStoreWithMiddleware(wrappedReducer);

class SimpleChatClient extends React.Component {
  componentWillMount() {
    const load = storage.createLoader(engine);
    load(store);
  }
  render() {
    return (
      <Provider store={store}>
        {() => <App />}
      </Provider>
    );
  }
}


React.AppRegistry.registerComponent('SimpleChatClient', () => SimpleChatClient);
