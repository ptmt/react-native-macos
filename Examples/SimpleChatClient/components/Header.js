/* @flow */
'use strict';

import React,  {
  View,
  Text,
  StyleSheet,
  Animated,
  Component
} from 'react-native-desktop';


export default class Header extends Component {
  render() {
    return (
      <View style={styles.header}>
        <View style={styles.user}>
          <Text style={styles.userLabel}>@{this.props.user && this.props.user.username}</Text>
        </View>
      </View>
    );
  }
}


var styles = {
  // ------------ header
  header: {
    backgroundColor: '#555',
    height: 38,
    //flex: 1
  },
  user: {
    height: 38,
    padding: 4,
    position: 'absolute',
    right: 0,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    //backgroundColor: 'black',
  },
  userLabel: {
    color: 'white',
    marginRight: 10
  },
}
