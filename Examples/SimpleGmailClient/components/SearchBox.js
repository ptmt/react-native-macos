/* @flow */
'use strict';

var React = require('react-native-desktop');
var {
  View,
  StyleSheet,
  TextInput,
} = React;


class SearchBox extends React.Component {
  render() {
    return (
      <View style={styles.search}>
          <TextInput
            placeholder={'Search...'}
            style={styles.textinput}
            onChangeText={(code) => this.setState({code})}
          />
      </View>
    );
  }
}

var styles = StyleSheet.create({
  search: {
    margin: 20
    // flex: 1,
    // top: 10,
    // left: 300,
    // position: 'absolute'
  },
  textinput: {
    height: 30,
    // borderWidth: 0.5,
    // borderColor: '#0f0f0f',
    width: 450,
    fontSize: 16,
    padding: 4,
  },
});

module.exports = SearchBox;
