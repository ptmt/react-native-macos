/* @flow */

var React = require('react-native-desktop');

var {
  View,
  Text,
  AppRegistry,
  Animated
} = React;

class Game2048 extends React.Component {
  render() {
    return (
      <View style={{backgroundColor: '#444', flex: 1}}>
        <Text style={{color: '#ddd', fontSize: 40, marginTop: 20, textAlign:'center'}}>Hello world</Text>
      </View>
    );
  }

}

AppRegistry.registerComponent('2048', () => Game2048);
