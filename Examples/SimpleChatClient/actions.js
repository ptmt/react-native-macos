/* @flow */
'use strict';

import { discordLogin, getGateway, connect, getMessages, sendMessageToChannel } from './discordClient';

export const SIGNIN_REQUEST = 'SIGNIN_REQUEST';
export const SIGNIN_SUCCESS = 'SIGNIN_SUCCESS';
export const SIGNIN_FAILURE = 'SIGNIN_FAILURE';

export const GOT_GATEWAY = 'GOT_GATEWAY';
export const GENERAL_ERROR = 'GENERAL_ERROR';
export const GOT_MESSAGE = 'GOT_MESSAGE';

export const CHANNEL_SELECTED = 'CHANNEL_SELECTED';
export const MESSAGES_LOADED = 'MESSAGES_LOADED';

export const MESSAGE_IS_SENDING = 'MESSAGE_IS_SENDING';
export const MESSAGE_SENT = 'MESSAGE_SENT';


export function login(email: string, password: string): any {
  if (!email || !password) {
    return {
      type: SIGNIN_FAILURE,
      error: 'These fields cannot be empty: email and password' // most stupid error message ever
    };
  }

  return dispatch => {
    dispatch({
      type: SIGNIN_REQUEST,
      email,
      password
    });

    discordLogin(email, password).then((token) => {
      return dispatch({
        type: SIGNIN_SUCCESS,
        token
      });
    }).catch(e => {
      return dispatch({
        type: SIGNIN_FAILURE,
        error: e
      })
    });
  }
}

function onMessageRecieved(messagePayload) {
  return {
    type: GOT_MESSAGE,
    messagePayload
  };
}

export function init(): any {
  return (dispatch, getState) => {
    getGateway(getState().token).then((gatewayUrl) => {
      return dispatch({
        type: GOT_GATEWAY,
        gatewayUrl
      });
    }).then(() => connect(
      getState().token,
      getState().gatewayUrl,
      (payload) => {
        dispatch(onMessageRecieved(payload));
        if (!getState().selectedChannel) {
          dispatch(onChannelSelect(payload.servers[0].channels[0].id));
        }
      })
    )
    .catch(e => {
      return dispatch({
        type: GENERAL_ERROR,
        error: e
      });
    });
  };
}

export function onChannelSelect(channelId: string): any {
  return (dispatch, getState) => {
    dispatch({
      type: CHANNEL_SELECTED,
      selectedChannel: channelId,
    });

    getMessages(getState().token, channelId).then((messages) => {
      return dispatch({
        type: MESSAGES_LOADED,
        messages
      });
    })
    .catch(e => {
      return dispatch({
        type: GENERAL_ERROR,
        error: e
      });
    });
  };

}

export function sendMessage(text:string): any {
  return (dispatch, getState) => {
    dispatch({
      type: MESSAGE_IS_SENDING
    });

    sendMessageToChannel(getState().token, getState().selectedChannel, text).then((res) => {
      return dispatch({
        type: MESSAGE_SENT,
        messageBody: text,
        res: res
      });
    })
    .catch(e => {
      return dispatch({
        type: GENERAL_ERROR,
        error: e
      });
    });
  };
}
