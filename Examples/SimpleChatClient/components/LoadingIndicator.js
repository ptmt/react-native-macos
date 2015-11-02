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
    this.state = { scale: new Animated.Value(1)};
  }
  componentDidMount() {
    this.pulse();
  }
  pulse() {
    const replay = () => {
      const a = setTimeout(() => this.pulse(), 400);
    } // to pass flow check
    this.state.scale.setValue(1);
    Animated.timing(this.state.scale, {
      toValue: 10
    }).start(replay);
  }

  render(): ReactElement {
    const { scale } = this.state;
    const interpolated = scale.interpolate({
      inputRange: [1, 4, 8, 10],
      outputRange: [1, 1.2, 1.1, 1.15,],
    });
    const animatedStyles = {transform: [ { scale: interpolated } ]};
    return (
      <Animated.Text style={[this.props.style, animatedStyles]}>
        {this.props.children}
      </Animated.Text>
    );
  }
}
