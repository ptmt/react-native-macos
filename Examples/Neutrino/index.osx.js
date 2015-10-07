/* @flow */
'use strict';

var React = require('react-native-desktop');

var {
  View,
  Text,
  AppRegistry
} = React;

class Neutrino extends React.Component {
  render() {
    return (
      <View style={{backgroundColor: '#000', flex: 1}}>
        <Text style={{color: '#ddd'}}>Hello world</Text>
      </View>
    );
  }
}

AppRegistry.registerComponent('Neutrino', () => Neutrino);
