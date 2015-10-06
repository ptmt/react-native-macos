/* @flow */
'use strict';

var React = require('react-native-desktop');

var {
  View
} = React;

class Neutrino extends React.Component {
  render() {
    return (
      <View style={{backgroundColor: 'black'}}>
      </View>);
  }
}


React.AppRegistry.registerComponent('Neutrino', () => Neutrino);
