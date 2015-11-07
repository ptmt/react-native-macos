/* @flow */
'use strict';

import React, { Component, View } from 'react-native-desktop';
import SigninForm from './SigninForm';
import ChatLayout from './ChatLayout';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux/native';
import * as Actions from '../actions';

class App extends Component {
  render() {
    const actions = bindActionCreators(Actions, this.props.dispatch);
    return (
      <View style={{flex: 1}}>
        {!this.props.token && this.props.loaded && <SigninForm login={actions.login} {...this.props}/>}
        {this.props.token && <ChatLayout {...this.props} actions={actions}/>}
      </View>
    );
  }
}

function mapStateToProps(state) {
  return state;
}

const AppContainer = connect(mapStateToProps)(App);

module.exports = AppContainer;
