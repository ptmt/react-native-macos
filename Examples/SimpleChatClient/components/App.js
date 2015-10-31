/* @flow */

import React, { Component, View } from 'react-native-desktop';
import SigninForm from './SigninForm';
import ChatLayout from './ChatLayout';
import { bindActionCreators } from 'redux';
import { Provider, connect } from 'react-redux/native';
import * as Actions from '../actions';

class App extends Component {
  constructor() {
    super();
    this.state = {
      token: 'MTAzNDE3Mzk3Mjg0NzI4ODMy.CQukiw.SqWM0JEgJGh9c5N9vp5xVGWYPZw'
      // user: {
      //   username: 'ptmt'
      // },
      // servers: [
      //   {
      //     name: 'reactiflux',
      //     channels: [
      //       {
      //         name: 'channel',
      //         id: 1,
      //         topic: 'long description about channel'
      //       }
      //     ]
      //  }
      // ]
    };
  }
  componentDidMount() {
    //discordClient
      //.login('muakacho@gmail.com', 'rtWCNeJK6Jwe7d')
      //.then(token => this.setState({token}))
      //.then(token => discordClient.getGateway(token));
      //.then(gateway =>
      //  discordClient.connect(this.state.token, 'wss://gateway-fafnir.discord.gg', (state) => this.setState(state))
  }
  onChannelSelect(channelId) {
    this.setState({
      selectedChanel: channelId
    });
    discordClient
      .getMessages(this.state.token, channelId)
      .then(messages => this.setState({messages}));
  }
  render() {
    const actions = bindActionCreators(Actions, this.props.dispatch);
    return (
      <View style={{flex: 1}}>
        {!this.props.token && <SigninForm login={actions.login} {...this.props}/>}
        {this.props.token && <ChatLayout {...this.props} />}
      </View>
    );
  }
  render1() {
    return (
      <View style={{flex: 1}}>

      </View>
    );
  }
}

function mapStateToProps(state) {
  return state;
}

const AppContainer = connect(mapStateToProps)(App);

module.exports = AppContainer;
