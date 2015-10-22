/* @flow */
'use strict';

// TODO: why import is not working?
var React = require('react-native-desktop');

var {
  View,
  AppRegistry,
} = React;

var SigninForm = require('./components/SigninForm');
var MailLayout = require('./components/MailLayout');

class SimpleGmailClient extends React.Component {
  constructor() {
    super();
    this.state = {};
  }
  render() {
    return (
      <View style={{flex: 1}}>
        {!this.state.access_token &&
          <SigninForm onSignin={(tokens) => this.setState(tokens)}/>
        }
        {this.state.access_token &&
          <MailLayout {...this.state} />
        }
      </View>
    );
  }
  onSignin(token) {

  }

}


AppRegistry.registerComponent('SimpleGmailClient', () => SimpleGmailClient);
