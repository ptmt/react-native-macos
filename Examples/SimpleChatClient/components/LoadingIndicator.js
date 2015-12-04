/* @flow */
'use strict';

import React,  {
  View,
  Text,
  ActivityIndicatorIOS,
} from 'react-native-desktop';

export default class LoadingIndicator extends React.Component {
  componentWillUnmount() {
    console.log('on unmount');
  }
  render(): ReactElement {
    const visibilityStyle = this.props.visible ? { opacity: 0} : {};
    console.log(this.props.children, visibilityStyle)
    return (
      <View style={[styles.container, visibilityStyle]}>
        <ActivityIndicatorIOS size="large" style={{width: 40, alignSelf: 'center'}}/>
        <Text>{this.props.children}</Text>
      </View>
    );
  }
}

const styles = {
  container: {flex: 1, marginTop: 100, alignItems: 'center', justifyContent: 'center'}
};
