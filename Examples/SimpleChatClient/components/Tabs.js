/* @flow */
'use strict';

import React,  {
  View,
  Text,
  StyleSheet,
  TouchableHighlight,
  TouchableOpacity,
  TouchableWithoutFeedback,
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

    const {name, active, id, onChannelSelect} = this.props;
    const additionalStyles = active ? {} : (this.state.hovered ? styles.notActiveButHovered : styles.notActive);
    return (
      <TouchableOpacity
        style={[styles.tab, styles.tabWrapper, additionalStyles]}
        onMouseEnter={() => this.setState({hovered: true})}
        onMouseLeave={() => this.setState({hovered: false})}
        onPress={() => onChannelSelect(id)}>
          <View style={[styles.closeButton, {opacity: this.state.hovered ? 1 : 0}]}>
            <Text style={[styles.tabTitleClose]}>{'×'}</Text>
          </View>
          <Text style={[styles.tabTitle, active ? {} : styles.nonActiveTitle]}>#{name}</Text>
      </TouchableOpacity>
    );
  }
}

export default class Tabs extends React.Component {
  render() {
    const tabs = this.props.tabs.map((t, i) => {
      return <Tab
        key={i}
        {...t}
        active={t.id === this.props.selectedChannel}
        onChannelSelect={this.props.actions.onChannelSelect} />
    });

    return (
      <View style={styles.tabs}>
        {tabs}
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
    height: 24,
    borderColor: '#bbb',
    borderLeftWidth: 0,
    borderRightWidth: 0.5,
    borderTopWidth: 0.5,
    borderBottomWidth: 0.5,
    backgroundColor: 'transparent'
  },
  tabWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center'
  },
  tabTitle: {
    color: 'black',
    fontSize: 11
  },
  closeButton: {
    position: 'absolute',
    left: 5,
    top: -2, // temporary workaround
    height: 24,
    justifyContent: 'center',
    alignItems: 'center'
  },
  tabTitleClose: {
    fontSize: 20,
    padding: 0,
    margin: 0,
    fontWeight: '200'
  },
  notActive: {
    backgroundColor: '#ddd'
  },
  notActiveButHovered: {
    backgroundColor: '#bbb'
  },
  nonActiveTitle: {
    color: '#444'
  }
});
