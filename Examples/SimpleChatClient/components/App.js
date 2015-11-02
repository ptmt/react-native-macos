/* @flow */

import React, { Component, View } from 'react-native-desktop';
import SigninForm from './SigninForm';
import ChatLayout from './ChatLayout';
import { bindActionCreators } from 'redux';
import { Provider, connect } from 'react-redux/native';
import * as Actions from '../actions';

class App extends Component {
  // onChannelSelect(channelId) {
  //   this.setState({
  //     selectedChanel: channelId
  //   });
  //   discordClient
  //     .getMessages(this.state.token, channelId)
  //     .then(messages => this.setState({messages}));
  // }
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
