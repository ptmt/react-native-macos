/* @flow */
'use strict';

import React,  {
  View,
  Text,
  StyleSheet,
  Animated
} from 'react-native-desktop';

export default class LoadingIndicator extends React.Component {
  constructor() {
    super();
    this.state = {
      animatedColor: new Animated.Value(0)
    };
  }
  componentDidMount() {
    this.pulse(false);
  }
  pulse(back: boolean) {
    Animated.timing(this.state.animatedColor, {
      toValue: back ? 0 : 1,
      duration: 1000
    }).start(() => {
      this.pulseTimer = setTimeout(() => this.pulse(!back), 500);
    });
  }

  componentWillUnmount() {
    clearTimeout(this.pulseTimer);
  }

  render(): ReactElement {
    const rand = () => Math.floor(Math.random() * 255);
    const fromColors = [1, 2, 3].map(c => rand()).join(', ');
    const toColors = [1, 2, 3].map(c => rand()).join(', ');
    const animatedColor = this.state.animatedColor.interpolate({
        inputRange: [0, 1],
        outputRange: [
          'rgb(' + fromColors.toString() + ')',
          'rgb(' + toColors.toString() + ')'
        ]
    });
    return (
      <View style={{alignItems: 'center', justifyContent: 'center', width: this.props.width}}>
        <Animated.Text style={[this.props.style, {fontSize: 20, color: animatedColor}]}>
          {this.props.children}
        </Animated.Text>
      </View>
    );
  }
}
