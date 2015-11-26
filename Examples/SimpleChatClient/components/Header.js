/* @flow */
'use strict';

import React,  {
  View,
  Text,
  StyleSheet,
  Animated,
  Component,
  TouchableHighlight,
  Image
} from 'react-native-desktop';

import Tabs from './Tabs';

export default class Header extends Component {
  render() {
    console.log(this.props);
    return (
      <View style={styles.header}>
        <Tabs tabs={[{title: '#general', active: true} , {title: '#react-native', active: false}]} />
        <View style={styles.user} onPress={() => this.props.exit()}>
          <Text style={styles.userLabel}>@{this.props.user && this.props.user.username}</Text>
          <Image
            source={{uri: 'https://cdn3.iconfinder.com/data/icons/fez/512/FEZ-04-64.png'}}
            style={{width: 16, height: 16}} />
        </View>
      </View>
    );
  }
}


var styles = {
  // ------------ header
  header: {
    height: 24,
    //flex: 1,
    flexDirection: 'row'
  },
  user: {
    height: 24,
    //position: 'absolute',
    right: 0,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    borderColor: '#bbb',
    borderWidth: 0.5,
    //backgroundColor: '#555',
    paddingHorizontal: 20
    //backgroundColor: 'black',
  },
  userLabel: {
    color: '#333',
    fontWeight: '200',
    fontSize: 10,
    marginRight: 10
  },
}
