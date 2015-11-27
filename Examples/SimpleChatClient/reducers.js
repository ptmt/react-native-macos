/* @flow */
'use strict';

import {
  SIGNIN_REQUEST, SIGNIN_SUCCESS, SIGNIN_FAILURE,
  GOT_GATEWAY, GENERAL_ERROR, GOT_MESSAGE,
  MESSAGES_LOADED, CHANNEL_SELECTED,
  MESSAGE_IS_SENDING, MESSAGE_SENT
} from './actions';

import { LOAD, SAVE } from 'redux-storage';

type GlobalState = any;

const defaultState: GlobalState = {
  isLoading: false,
  tabs: []
};

export default function reducer(state: GlobalState, action: any): GlobalState {
  if (!state) { state = defaultState; } // Flow default parameter
  switch (action.type) {
    case SIGNIN_REQUEST:
      return {
        ...state,
        error: null,
        isLoading: true
      };
    case SIGNIN_SUCCESS:
      return {
        ...state,
        error: null,
        isLoading: false,
        token: action.token
      };
    case SIGNIN_FAILURE:
      return {
        ...state,
        isLoading: false,
        error: action.error
      };
    case LOAD:
      // TODO: fix that serialization issue
      if (state.servers) {
        state.servers = Object.keys(state.servers).map(m => state.servers[m]);
      }
      if (state.messages) {
        state.messages = Object.keys(state.messages).map(m => state.messages[m]);
      }
      if (state.tabs) {
        state.tabs = Object.keys(state.tabs).map(m => state.tabs[m]);
      }
      return { ...state, loaded: !state.loaded};
    case SAVE:
      return state;
    case GOT_GATEWAY:
      return { ...state, gatewayUrl: action.gatewayUrl };

    case GENERAL_ERROR:
      return { ...state, error: action.error };

    case GOT_MESSAGE:
      if (action.messagePayload.servers) {
        state = {...state, servers: action.messagePayload.servers }; // TODO: smart merge
      }
      if (action.messagePayload.user) {
        state = {...state, user: action.messagePayload.user};
      }
      return state;

    case CHANNEL_SELECTED:
      if (!state.tabs) {
        state.tabs = [];
      }
      //state.tabs = [];
      const channel = findChannel(state.servers, action.selectedChannel);
      const alreadyOpened = state.tabs.filter(c => c.id === action.selectedChannel).length > 0;
      return {
        ...state,
        messages: null,
        selectedChannel: action.selectedChannel,
        tabs: alreadyOpened ? state.tabs : state.tabs.concat(channel)
      };

    case MESSAGES_LOADED:
      return {...state, messages: action.messages};

    case MESSAGE_IS_SENDING:
      return {...state, sending: true};

    case MESSAGE_SENT:
      return {
        ...state,
        sending: false,
        messages: state.messages.concat({
          author: state.user,
          timestamp: new Date(),
          content: action.res.content,
          id: action.res.id
        })
      };

    default:
      return state;
  }
}

function findChannel(servers: Array<any>, channelId: string): any {
  return [].concat.apply([], servers.map(s => s.channels)).filter(c => c.id === channelId)[0];
}
