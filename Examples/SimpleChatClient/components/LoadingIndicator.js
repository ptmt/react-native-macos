/* @flow */
'use strict';

import React,  {
  View,
  Text,
  StyleSheet,
  ActivityIndicatorIOS,
  Animated
} from 'react-native-desktop';

export default class LoadingIndicator extends React.Component {
  componentWillUnmount() {
    console.log('on unmount');
  }
  render(): ReactElement {
    return (
      <View style={{flex: 1, marginTop: 100, alignItems: 'center', justifyContent: 'center'}}>
        <ActivityIndicatorIOS size="large" style={{width: 40, alignSelf: 'center'}}/>
        <Text>{this.props.children}</Text>
      </View>
    );
  }
}
