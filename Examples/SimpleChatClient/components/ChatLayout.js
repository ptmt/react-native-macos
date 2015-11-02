/* @flow */
'use strict';

var React = require('react-native-desktop');
var {
  View,
  StyleSheet,
  ScrollView,
  Dimensions,
  Text,
  ActivityIndicatorIOS,
  TouchableOpacity,
  TextInput
} = React;

import LoadingIndicator from './LoadingIndicator';
// React 0.14
// var Channel = (props) => {
//   <TouchableOpacity onPress={() => console.log(this.props.id)}>
//     <Text style={styles.channelText}>{props.name}</Text>
//     <Text style={styles.channelText}>{props.topic}</Text>
//   </TouchableOpacity>
// }

class Channel extends React.Component {
  render() {
    // TODO: add topic on hover <Text style={styles.channelTextDescription}>{this.props.topic}</Text>
    return (
      <TouchableOpacity onPress={() => this.props.onSelect()}>
        <Text style={[styles.channelText, this.props.isSelected ? {fontWeight: '800'} : {}]}>
          #{this.props.name.toLowerCase()}
        </Text>
      </TouchableOpacity>
    );
  }
}


class ChatLayout extends React.Component {
  constructor() {
    super();
    this.state = {
      loading: true
    };
  }
  componentDidMount() {
    this.props.actions.init();
  }
  render() {
    var servers = this.props.servers && this.props.servers.map(server => {
      return (
        <View>
          <Text style={styles.serverText}>-- {server.name} --</Text>
          {server.channels.map(c => <Channel {...c}
              isSelected={this.props.selectedChanel === c.id}
              onSelect={() => this.props.onChannelSelect(c.id)} />)}
        </View>
      );
    });
    var messages = this.props.messages && this.props.messages.map(message => {
      var time = new Date(message.timestamp).getHours() + ':' + new Date(message.timestamp).getMinutes();
      return (
        <View style={styles.message}>
          <Text style={styles.messageTimestamp}>{time}</Text>
          <Text style={styles.messageUsername}>{message.author.username}</Text>
          <Text style={styles.messageText}>{message.content}</Text>
        </View>
      );
    });
    return (
      <View style={styles.container}>
        <View style={styles.user}>
          <Text style={styles.userLabel}>@{this.props.user && this.props.user.username}</Text>
        </View>
        <View style={styles.channels}>
          <ScrollView style={{height: Dimensions.get('window').height}}>
            {servers || <LoadingIndicator style={styles.messageText}>Loading channels..</LoadingIndicator>}
          </ScrollView>
        </View>
        <View style={styles.messages}>
          <ScrollView style={styles.messagesScrollContainer}>
            {messages || <LoadingIndicator style={styles.messageLoader}>Loading messages..</LoadingIndicator>}
          </ScrollView>
          <View style={styles.inputWrapper}>
            <TextInput
              style={styles.input}
              multiline={false}
              placeholder={'Type message...'}
            />
            <TouchableOpacity style={styles.button}>
              <Text style={styles.buttonCaption}>Send</Text>
            </TouchableOpacity>
          </View>
        </View>
        <View style={styles.spinner}>
          <Text>Loading...</Text>
          <ActivityIndicatorIOS animating={!this.props.user} size={'large'}/>
        </View>
      </View>
    );
  }

}

var styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#333',
    flexDirection: 'row'
  },
  user: {
    right: 30,
    top: 10,
    padding: 7,
    backgroundColor: '#777',
    position: 'absolute'
  },
  userLabel: {
    color: 'white',
  },
  channels: {
    width: 300,
    padding: 30,
    height: Dimensions.get('window').height // TODO: dynamic
  },
  serverText: {
    color: '#ccc',
    textAlign: 'center',
  },
  channelText: {
    color: 'white',
    fontWeight: '300',
    marginBottom: 8
  },
  channelTextDescription: {
    color: '#ccc',
    fontSize: 10
  },
  // ------- input
  inputWrapper: {
    position: 'absolute',
    bottom: 0,
    width: 500, // TODO: dynamic
    backgroundColor: 'white',
    borderRadius: 10,
    marginLeft: 20,
    height: 75,
    flex: 1,
    flexDirection: 'row'
  },
  input: {
    height: 70,
    // borderWidth: 0.5,
    // borderColor: '#0f0f0f',
    flex: 1,
    fontSize: 18,
    padding: 10,
    color: '#666'
  },
  button: {
    margin: 10,
    borderColor: '#009aff',
    borderWidth: 1,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 10,
    //flex: 1,
  },
  buttonCaption: {
    textAlign: 'center',
    color: '#009aff',
    fontSize: 20,
    padding: 0,
    margin: 0
  },
  // --------- messages
  messages: {
    backgroundColor: '#eee',
    flex: 1,
    top: 0,
  },
  messagesScrollContainer: {
    flex: 1
  },
  messageText: {
    color: '#ddd',
    marginLeft: 4,
    width: Dimensions.get('window').width - 400
  },
  message: {
    flex: 1,
    flexDirection: 'row',
    marginLeft: 10,
    marginBottom: 5
  },
  messageTimestamp: {
    color: '#888',
    marginRight: 10
  },
  messageUsername: {
    color: '#ddd',
    fontWeight: '800'
  },
  messageLoader: {
    fontSize: 20,
    color: '#333',
    //textAlign: 'center',
    marginTop: 20,
    marginLeft: 100
  },
  // -----------
  spinner: {
    position: 'absolute',
    // top: 10,
    // left: 200
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center'
  }
});
module.exports = ChatLayout;
