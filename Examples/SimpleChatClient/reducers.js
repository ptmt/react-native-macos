/* @flow */
import { SIGNIN_REQUEST, SIGNIN_SUCCESS, SIGNIN_FAILURE } from './actions';
import { LOAD, SAVE } from 'redux-storage';
import { combineReducers } from 'redux';

type GlobalState = any;

const defaultState: GlobalState = {
  isLoading: false
};

export default function reducer(state: GlobalState, action: any): GlobalState {
  if (!state) { state = defaultState; } // Flow default parameter
  switch (action.type) {
    case SIGNIN_REQUEST:
      return {
        ...state,
        error: null,
        isLoading: true
      }
    case SIGNIN_SUCCESS:
      return {
        ...state,
        error: null,
        isLoading: false,
        token: action.token
      }
    case SIGNIN_FAILURE:
      return {
        ...state,
        isLoading: false,
        error: action.error
      }
    case LOAD:
      console.log(state, action);
      return { ...state, loaded: true };

    case SAVE:
      console.log('Written to disk!');
    default:
      return state
  }
}

//
// function byId(state = {}, action) {
//   switch (action.type) {
//     case RECEIVE_PRODUCTS:
//       return {
//         ...state,
//         ...action.products.reduce((obj, product) => {
//           obj[product.id] = product
//           return obj
//         }, {})
//       }
//     default:
//       const { productId } = action
//       if (productId) {
//         return {
//           ...state,
//           [productId]: products(state[productId], action)
//         }
//       }
//       return state
//   }
// }
