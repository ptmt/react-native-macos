/* @flow */
'use strict';

var React = require('react-native-desktop');
var {
  View,
  StyleSheet,
  ScrollView,
  Dimensions,
  Text,
  TouchableOpacity,
  TouchableHighlight,
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
  constructor() {
    super();
    this.state = {isHovered: false};
  }
  render() {
    // TODO: add topic on hover <Text style={styles.channelTextDescription}>{this.props.topic}</Text>
    return (
      <TouchableHighlight
      onPress={() => this.props.onSelect()}
      onMouseEnter={() => this.setState({isHovered: true})}
      onMouseLeave={() => this.setState({isHovered: false})}
      style={[styles.channelBox, this.props.isSelected ? {backgroundColor: '#009aff'} : {}]}>
        <Text style={[styles.channelText,
          this.props.isSelected ? {fontWeight: '800', color: 'white'} : {},
          this.state.isHovered && !this.props.isSelected ? {color: '#009aff'} : {}
        ]}>
          <Text style={{color: '#999'}}>#</Text>{this.props.name.toLowerCase()}
        </Text>
      </TouchableHighlight>
    );
  }
}


class ChatLayout extends React.Component {
  constructor() {
    super();
    this.state = {};
  }
  componentDidMount() {
    this.props.actions.init();
  }
  render1() {
    return <TextInput
      style={styles.input}
      multiline={false}
      placeholder={'Type message...'}
    />;
  }
  render() {
    const servers = this.props.servers && this.props.servers.map((server, serverKey) => {
      return (
        <View key={serverKey}>
          <Text style={styles.serverText}>{server.name}</Text>
          {server.channels.map(c => <Channel {...c}
              key={c.id}
              isSelected={this.props.selectedChannel === c.id}
              onSelect={() => this.props.actions.onChannelSelect(c.id)} />)}
        </View>
      );
    });

    const messages = this.props.messages && this.props.messages.map(message => {
      const date = new Date(message.timestamp);
      var time = ('0' + date.getHours()).slice(-2) + ':' +   ('0' + date.getMinutes()).slice(-2);
      return (
        <View style={styles.message} key={message.id}>
          <Text style={styles.messageTimestamp}>{time}</Text>
          <Text style={styles.messageUsername}>{'<'}{message.author.username}{'>'}</Text>
          <Text style={styles.messageText}>{message.content}</Text>
        </View>
      );
    });
    return (
      <View style={styles.container}>
        <View style={styles.channels}>
          <View style={styles.user}>
            <Text style={styles.userLabel}>@{this.props.user && this.props.user.username}</Text>
            <Text style={{color: '#ddd', fontSize: 10}}>Sign out</Text>
          </View>
          <ScrollView style={styles.channelsScroll} contentContainerStyle={styles.channelScrollContainer} showsVerticalScrollIndicator={true}>
            {servers || <LoadingIndicator style={styles.messageText}>Loading channels..</LoadingIndicator>}
          </ScrollView>
        </View>
        <View style={styles.messages}>
          <ScrollView style={styles.messagesScrollContainer} showsVerticalScrollIndicator={true}>
            {messages || <LoadingIndicator style={styles.messageLoader}>Loading messages..</LoadingIndicator>}
          </ScrollView>
          <View style={styles.inputWrapper}>
            <TextInput
              style={styles.input}
              multiline={true}
              placeholder={'Type message...'}
            />
            <TouchableOpacity style={styles.button} onPress={() => this.props.actions.sendMessage('Test message')}>
              <Text style={styles.buttonCaption}>{this.props.sending ? 'Sending...' : 'Send (⌘+Enter)'}</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    );
  }

}

var styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'white',
    flexDirection: 'row'
  },
  user: {
    margin: 0,
    padding: 4,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'black',
  },
  userLabel: {
    color: 'white',
    marginRight: 10
  },
  // ------------ channels
  channels: {
    width: 200,
    backgroundColor: '#eee',
    height: Dimensions.get('window').height // TODO: dynamic
  },
  channelScroll: {
    height: Dimensions.get('window').height // TODO: dynamic
  },
  channelScrollContainer: {
    //paddingHorizontal: 10
  },
  serverText: {
    color: '#666',
    //letterSpacing: 5,
    paddingVertical: 5,
    paddingHorizontal: 6,
    fontSize: 12,
    fontWeight: '700'
    //textAlign: 'center',
  },
  channelBox: {
    paddingHorizontal: 10,
    paddingVertical: 4
  },
  channelText: {
    color: 'black',
    fontWeight: '300',
    fontSize: 12,
    paddingLeft: 10
  },
  channelTextDescription: {
    color: '#ccc',
    fontSize: 10
  },
  // ------- input
  inputWrapper: {
    borderWidth: 1,
    borderColor: '#ddd',
    //borderLeftColor: '#eee',
    backgroundColor: '#eee',
    padding: 5,
    flexDirection: 'row'
  },
  input: {
    height: 70,
    width: 500,
    backgroundColor: 'white',
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
    //flex: 1,
    top: 0,
  },
  messagesScrollContainer: {
    //flex: 1,
    height: Dimensions.get('window').height - 150
    //width: Dimensions.get('window').width - 400,
  },
  message: {
    flex: 1,
    flexDirection: 'row',
    marginLeft: 10,
    marginBottom: 5,
  },
  messageTimestamp: {
    color: '#999',
    marginRight: 5,
    //fontSize: 12
  },
  messageUsername: {
    color: '#222',
    width: 150,
    textAlign: 'right',
    fontWeight: '600'
  },
  messageText: {
    //position: 'absolute',
    color: '#222',
    marginLeft: 4,
    width: Dimensions.get('window').width - 700 // TODO: why it's not wrap automatically
  },
  messageLoader: {
    fontSize: 20,
    color: '#333',
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
