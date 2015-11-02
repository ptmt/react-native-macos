/* @flow */
import { discordLogin, getGateway, connect } from './discordClient';

export const SIGNIN_REQUEST = 'SIGNIN_REQUEST';
export const SIGNIN_SUCCESS = 'SIGNIN_SUCCESS';
export const SIGNIN_FAILURE = 'SIGNIN_FAILURE';

export const GOT_GATEWAY = 'GOT_GATEWAY';
export const GENERAL_ERROR = 'GENERAL_ERROR';
export const GOT_MESSAGE = 'GOT_MESSAGE';

export function login(email: string, password: string): any {
  if (!email || !password) {
    return {
      type: SIGNIN_FAILURE,
      error: 'These fields cannot be empty: email and password' // most stupid error message ever
    }
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
      (payload) => dispatch(onMessageRecieved(payload)))
    )
    .catch(e => {
      return dispatch({
        type: GENERAL_ERROR,
        error: e
      })
    })
  }

}
