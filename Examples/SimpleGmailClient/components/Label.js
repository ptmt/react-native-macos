/* @flow */
'use strict';

var React = require('react-native-desktop');
var {
  Text,
  StyleSheet,
  TouchableHighlight,
} = React;

class Label extends React.Component {
  constructor() {
    super();
    this.state = {};
  }
  componentDidMount() {
    if (this.props.name === 'INBOX') {
      fetch('https://www.googleapis.com/gmail/v1/users/me/labels/INBOX/?access_token=' + this.props.access_token)
        .then(r => r.json())
        .then(r => {
          this.setState({
            messagesUnread: r.messagesUnread
          });
        });
    }

  }
  render() {
    //console.log(this.props)
    var {name, isSelected} = this.props;
    var unread = this.state.messagesUnread || this.state.messagesUnread === 0 ? '(' + this.state.messagesUnread + ')' : '';
    return (
      <TouchableHighlight style={[styles.labelItem, isSelected ? {backgroundColor: '#c10'} : {}]} onPress={()=>this.props.onSelect(name)}>
        <Text style={[styles.labelText, isSelected ? {color: 'white', fontWeight: '800'} : {}]}>{name} {unread}</Text>
      </TouchableHighlight>
    );
  }
}

var styles = StyleSheet.create({
  labelItem: {
    padding: 5
  },
  labelText: {
    fontSize: 12
  }
});

module.exports = Label;
