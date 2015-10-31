/* @flow */
import { discordLogin } from './discordClient';

export const SIGNIN_REQUEST = 'SIGNIN_REQUEST';
export const SIGNIN_SUCCESS = 'SIGNIN_SUCCESS';
export const SIGNIN_FAILURE = 'SIGNIN_FAILURE';

export function login(email, password) {
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
      console.error(e);
      return dispatch({
        type: SIGNIN_FAILURE,
        error: e
      })
    });
  }
}
