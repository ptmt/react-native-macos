/**
 * @flow
 */
'use strict';

const React = require('React');
const ReactNative = require('react-native');

const {
  StyleSheet,
  Text,
  View,
  Appearance,
  TextInput,
  Slider,
} = ReactNative;

class AppearanceListenerExample extends React.Component<{}> {
  
  componentDidMount() {
    new Appearance().addEventListener("onAppearanceChange", e => this.setState(e));
  }
  state: any = Appearance.initial;
  render() {
   
    return (
      <View style={styles.container}>
        <Text>Current appearance name: <Text style={{ fontWeight: "bold"}} >{this.state.currentAppearance}</Text></Text>
      </View>
    );
  }
}

class ColorHelpersExample extends React.Component<{}, { color: string, level: Number, highlightedColor?: string }> {
  
  state = { color: "#ddd", level: 0}
  componentDidMount() {
    this.changeHighlightColor(0)
  }
  changeHighlightColor = async (level) => {
    this.setState({ level })
    
    const highlightedColor = await Appearance.highlightWithLevel(this.state.color, level);
    this.setState({ highlightedColor })
    const shadowedColor = await Appearance.shadowWithLevel(this.state.color, level);
    this.setState({ shadowedColor })
  }
  render() {
    return (
      <View style={styles.container}>
        <View style={{ flexDirection: "row", justifyContent: "space-between"}}>
          <Text>Input color</Text>
          <TextInput value={this.state.color} style={{ width: "50%"}} onChangeText={color => this.setState({ color }, () => this.changeHighlightColor(this.state.level))} />
        </View>
       
        <Text>Level {this.state.level} </Text>
        <Slider step={0.1} minimumValue={0} maximumValue={1} onValueChange={this.changeHighlightColor} />
        
        <View style={{ flexDirection: "row", justifyContent: "space-between"}}>
          {this.state.highlightedColor && <View style={[{ backgroundColor: this.state.highlightedColor }, styles.colorBlock]}><Text>highlighted</Text></View>}
          {this.state.highlightedColor && <View style={[{ backgroundColor: this.state.shadowedColor}, styles.colorBlock]}><Text>shadowed</Text></View>}
        </View>
      </View>
    );
  }
}

class ColorsExample extends React.Component<{}> {
  
  componentDidMount() {
    new Appearance().addEventListener("onAppearanceChange", e => this.setState(e));
  }
  state: any = Appearance.initial;
  render() {
    return (
      <View style={styles.container}>
        {Object.keys(this.state.colors).sort((a, b) => a > b ? 1 : -1).map(key =>
          <View key={key} style={{ marginVertical: 6 }}>
            <Text>{key}</Text> 
            <Text style={{ fontSize: 11, color: "gray" }} >{this.state.colors[key]}</Text>
            <View style={{ borderWidth: 0.5, borderColor: "gray", width: "100%", height: 30, marginVertical: 5, backgroundColor: this.state.colors[key] }} />
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
}, 
{
  title: 'Color helpers',
  render() {
    return (
      <ColorHelpersExample />
    );
  }
}, {
  title: 'Dynamic system colors (NSColor)',
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
  colorBlock: {
    width: "30%", height: 30, justifyContent: "center", alignItems: "center"
  }
});
