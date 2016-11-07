/**
 * @flow
 */
'use strict';

const React = require('React');
const ReactNative = require('react-native');
const {
  MenuManager,
  TouchableOpacity,
  StyleSheet,
  Text,
  TextInput,
  AlertIOS,
  View,
} = ReactNative;

const MenuManagerExample = React.createClass({
  getInitialState() {
    return {
      title: 'Example',
      itemTitle: '',
      items: [{
        title: 'First submenu',
        key: 'f',
        callback: () => AlertIOS.alert('Menu Example', 'You have clicked on the test item', [
          {text: 'OK', onPress: () => console.log('OK Pressed!')},
        ])
      }]
    };
  },

  _addNewSubmenu() {
    MenuManager.addSubmenu(this.state.title, this.state.items);
  },

  _addNewItemToSubmenu() {
    MenuManager.addItemToSubmenu(this.state.title, {
      title: this.state.itemTitle,
    });
  },

  render() {
    return (
      <View style={styles.container}>
        <Text>Enter title of the new submenu:</Text>
        <View style={styles.row}>
          <TextInput
            style={styles.input}
            placeholder={'Submenu title'}
            onChange={(e) => this.setState({title: e.nativeEvent.text})} />
          <TouchableOpacity style={styles.button} onPress={this._addNewSubmenu}>
            <Text style={styles.buttonText}>Add submenu</Text>
          </TouchableOpacity>
        </View>
        <Text>Enter title of the new item for submenu:</Text>
        <View style={styles.row}>
          <TextInput
            style={styles.input}
            placeholder={'Item title'}
            onChange={(e) => this.setState({itemTitle: e.nativeEvent.text})} />
          <TouchableOpacity style={styles.button} onPress={this._addNewItemToSubmenu}>
            <Text style={styles.buttonText}>Add item</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  },
});

exports.displayName = (undefined: ?string);
exports.framework = 'React';
exports.title = 'MenuManager';
exports.description = 'NSMenu APIs';
exports.examples = [{
  title: 'Managing Main Application Menu',
  render() {
    return (
      <MenuManagerExample />
    );
  }
}];

var styles = StyleSheet.create({
  container: {
    marginTop: 20,
    backgroundColor: 'transparent',
  },
  row: {
    flexDirection: 'row',
    flex: 1,
    marginTop: 20
  },
  button: {
    padding: 5
  },
  input: {width: 150, height: 30},
  buttonText: {
    color: 'darkblue'
  }
});
