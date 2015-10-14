# React Native Desktop

React Native fork for OS X. Codename "Lepton". 

## Current stage: hacking an prototype

![](http://i.imgur.com/QlhROpp.gif)
![](http://i.imgur.com/5US3q5j.gif)

```js
/* @flow */

var React = require('react-native-desktop');

var {
  View,
  Text,
  AppRegistry,
  Animated
} = React;

const hello = 'Hello world!';

class Neutrino extends React.Component {
  constructor() {
    super();
    this.state = { animatedColor : new Animated.Value(0) };
  }

  blinking(reverse) {
    Animated.timing(
      this.state.animatedColor,
      {
        toValue: reverse ? 0 : 1,
        duration: 3000
      }
    ).start(() => this.blinking(!reverse));
  }

  componentDidMount() {
    this.blinking();
  }

  render() {
    const text = hello.split('').map(word => {
      const rand = () => Math.floor(Math.random() * 255);
      const fromColors = [1, 2, 3].map(c => rand()).join(', ');
      const toColors = [1, 2, 3].map(c => rand()).join(', ');
      const color = this.state.animatedColor.interpolate({
         inputRange: [0, 1],
         outputRange: ['rgb(' + fromColors + ')','rgb(' + toColors + ')']}); // TODO: template strings
      return <Animated.Text style={{color}}>{word}</Animated.Text>;
    });

    return (
      <View style={{backgroundColor: '#444', flex: 1}}>
        <Text style={{color: '#ddd', fontSize: 40, marginTop: 20, textAlign:'center'}}>{text}</Text>
      </View>
    );
  }

}

AppRegistry.registerComponent('Neutrino', () => Neutrino);

```

## Roadmap to 0.1.0

https://github.com/ptmt/react-native-desktop/issues/1
