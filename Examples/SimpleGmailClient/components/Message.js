/* @flow */
'use strict';

var React = require('react-native-desktop');
var {
  View,
  Text,
  StyleSheet,
} = React;

class Message extends React.Component {
  constructor() {
    super();
    this.state = {};
  }
  componentDidMount() {
    fetch('https://www.googleapis.com/gmail/v1/users/me/messages/' + this.props.id + '/?access_token=' + this.props.access_token)
      .then(r => r.json())
      .then(r => {
        //console.log(r);
        this.setState({
          message: r
        });
      })
      .catch(e => console.log(e));
  }
  render() {
    var isUnread = this.state.message && this.state.message.labelIds.indexOf('UNREAD') > -1;
    var subject = this.state.message ? this.state.message.payload.headers.filter(h => h.name === 'Subject')[0].value : 'Loading...';
    var snippet = this.state.message ? this.state.message.snippet.slice(-50) : '';
    var date = this.state.message ? new Date(parseInt(this.state.message.internalDate, 10)) : '';
    var fromField = this.state.message ? this.state.message.payload.headers.filter(h => h.name === 'From')[0].value.split('<')[0]: '';
    return (
      <View style={styles.messageItem}>
        <Text style={styles.messageText}>{fromField}</Text>
        <Text style={[styles.messageText, isUnread ? {fontWeight: '800'} : {}]}>{subject}</Text>
        <Text style={styles.messageText}>{snippet}</Text>
        <Text style={styles.messageText}>{date}</Text>
      </View>
    );
  }
}
var styles = StyleSheet.create({
  messageItem: {
    flex: 1,
    backgroundColor: 'white',
    flexDirection: 'row',
   borderBottomColor: '#ccc',
   borderBottomWidth: 1,
    padding: 8,
    width: 500,
  },
  messageText: {
    fontSize: 12,
    marginRight: 10
  }
});

module.exports = Message;
