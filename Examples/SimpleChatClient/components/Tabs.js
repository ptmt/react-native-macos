/* @flow */
'use strict';

import React,  {
  View,
  Text,
  StyleSheet,
  TouchableHighlight,
  Animated
} from 'react-native-desktop';


class Tab extends React.Component {
  constructor() {
    super();
    this.state = {
      hovered: false
    };
  }
  render() {
    const {title, active} = this.props.tab;
    const additionalStyles = active ? {} : (this.state.hovered ? styles.notActiveButHovered : styles.notActive);
    const closeButton = {position: 'absolute', left: 5};
    return (
      <TouchableHighlight
        style={[styles.tab, additionalStyles]}
        onMouseEnter={() => this.setState({hovered: true})}
        onMouseLeave={() => this.setState({hovered: false})}>
      
        <Text style={[styles.tabTitle, active ? {} : styles.nonActiveTitle]}>{title}</Text>
      </TouchableHighlight>
    );
  }
}

export default class Tabs extends React.Component {
  render() {
    return (
      <View style={styles.tabs}>
        {this.props.tabs.map((t, i) => <Tab key={i} tab={t} /> )}
      </View>
    );
  }
}

const styles = StyleSheet.create({
  tabs: {
    justifyContent: 'flex-start',
    flex: 1,
    height: 24,
    alignItems: 'stretch',
    flexDirection: 'row'
  },
  tab: {
    flex: 1,
    alignItems: 'center',
    height: 24,
    borderColor: '#bbb',
    borderLeftWidth: 0,
    borderRightWidth: 0.5,
    borderTopWidth: 0.5,
    borderBottomWidth: 0.5,
    justifyContent: 'center'
  },
  tabTitle: {
    color: 'black',
    fontSize: 11
  },
  notActive: {
    backgroundColor: '#ccc'
  },
  notActiveButHovered: {
    backgroundColor: '#bbb'
  },
  nonActiveTitle: {
    color: '#444'
  }
});
