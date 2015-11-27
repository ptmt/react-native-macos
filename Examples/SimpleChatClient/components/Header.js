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
    const { props } = this;
    // <Text style={styles.userLabel}>@{props.user && props.user.username}</Text>
    //   <Image
        // source={{uri: 'https://cdn3.iconfinder.com/data/icons/fez/512/FEZ-04-64.png'}}
        // style={{width: 16, height: 16}} />
    return (
      <View style={styles.header}>
        <View style={styles.user} onPress={() => this.props.exit()}>

        </View>
        <Tabs {...props} />

      </View>
    );
  }
}


var styles = {
  // ------------ header
  header: {
    //height: 24,
    //flex: 1,
    flexDirection: 'row'
  },
  user: {
    height: 24,
    //position: 'absolute',
    //right: 0,
    width: 200,
    // flexDirection: 'row',
    // justifyContent: 'center',
    // alignItems: 'center',
    // borderColor: '#bbb',
    // borderWidth: 0.5,
    //backgroundColor: '#555',
    //paddingHorizontal: 20
    //backgroundColor: 'black',
  },
  userLabel: {
    color: '#333',
    fontWeight: '200',
    fontSize: 10,
    marginRight: 10
  },
}
