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
  Appearance,
} = ReactNative;

class AppearanceListenerExample extends React.Component {
  
  componentDidMount() {
    new Appearance().addEventListener("onAppearanceChange", e => console.log(e))
  }
  render() {
    return (
      <View style={styles.container}>
        <Text>Current appearance: {Appearance.currentAppearance}</Text>
      </View>
    );
  }
}

class ColorsExample extends React.Component {
  
  componentDidMount() {
    new Appearance().addEventListener("onAppearanceChange", e => console.log(e))
  }
  render() {
    return (
      <View style={styles.container}>
        {Object.keys(Appearance.colors).map(key =>
          <View key={key} style={{ marginVertical: 6 }}>
            <Text>{key}</Text> 
            <Text style={{ fontSize: 11, color: "gray" }} >{Appearance.colors[key] }</Text>

            <View style={{ borderWidth: 0.5, borderColor: "gray", width: 100, height: 20, backgroundColor: Appearance.colors[key] }} />
          </View>
        )}
      </View>
    );
  }
}

exports.displayName = (undefined: ?string);
exports.framework = 'React';
exports.title = 'Appearance';
exports.description = 'macOS 10.14+ Mojave Appearance';
exports.examples = [{
  title: 'System Appearance listener',
  render() {
    return (
      <AppearanceListenerExample />
    );
  }
}, {
  title: 'System colors (NSColor)',
  render() {
    return (
      <ColorsExample />
    );
  }
}];

var styles = StyleSheet.create({
  container: {
    backgroundColor: 'transparent',
  },
  
});
