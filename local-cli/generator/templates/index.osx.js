/**
 * Sample React Native Desktop App
 * https://github.com/ptmt/react-native-desktop
 */
 import React from 'react';
 import ReactNative from 'react-native-desktop';
 const {
   AppRegistry,
   StyleSheet,
   Text,
   View,
 } = ReactNative;

const <%= name %> = React.createClass({
  render() {
    return (
      <View style={styles.container}>
        <Text style={styles.welcome}>
          Welcome to React Native Desktop!
        </Text>
        <Text style={styles.instructions}>
          To get started, edit index.osx.js
        </Text>
        <Text style={styles.instructions}>
          Press Cmd+R to reload,{'\n'}
          Or use Developer Menu
        </Text>
      </View>
    );
  }
});

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
});

AppRegistry.registerComponent('<%= name %>', () => <%= name %>);
