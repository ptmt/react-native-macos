/* @flow */
'use strict';

// TODO: why import is not working?
var React = require('react-native-desktop');

var {
  View,
  AppRegistry,
} = React;

var discordClient = require('./discordClient');
// var SigninForm = require('./components/SigninForm');
var ChatLayout = require('./components/ChatLayout');

class SimpleChatClient extends React.Component {
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
        discordClient.connect(this.state.token, 'wss://gateway-fafnir.discord.gg', (state) => this.setState(state))
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
    return (
      <View style={{flex: 1}}>
        <ChatLayout {...this.state} onChannelSelect={this.onChannelSelect.bind(this)}/>}
      </View>
    );
  }
}


AppRegistry.registerComponent('SimpleChatClient', () => SimpleChatClient);
