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

class Channel extends React.Component {
  constructor() {
    super();
    this.state = {isHovered: false};
  }
  render() {
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
          <Text style={{color: this.props.isSelected ? '#ddd' : '#666'}}>#</Text>{this.props.name.toLowerCase()}
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
  sendMessage(text: string) {
    if (!text) {
      return;
    }
    this.props.actions.sendMessage(text);
    this.setState({currentMessage: ''});
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
        <View style={[styles.message]} key={message.id}>
          <Text style={styles.messageTimestamp}>{time}</Text>
          <Text style={styles.messageUsername}>{'<'}{message.author.username}{'>'}</Text>
          <Text style={styles.messageText}>{message.content}</Text>
        </View>
      );
    });
    console.log(!messages)
    return (
        <View style={styles.container}>
          <View style={styles.channels}>
            {!servers && <LoadingIndicator>Loading channels..</LoadingIndicator>}
            <ScrollView style={styles.channelsScroll}
              contentContainerStyle={styles.channelScrollContainer}
              showsVerticalScrollIndicator={true}>
                {servers}
            </ScrollView>
          </View>
          <View style={styles.messages}>
            {!messages && <LoadingIndicator>Loading messages..</LoadingIndicator>}
            <ScrollView
                style={[styles.messagesScrollContainer]}
                autoScrollToBottom={true}
                showsVerticalScrollIndicator={true}>
                  {messages}
            </ScrollView>
            <View style={styles.inputWrapper}>
              <TextInput
                style={styles.input}
                multiline={true}
                placeholder={'Type message...'}
                onChangeText={(currentMessage) => this.setState({currentMessage})}
                value={this.state.currentMessage}
              />
              <TouchableOpacity style={styles.button} onPress={() => this.sendMessage(this.state.currentMessage)}>
                <Text style={styles.buttonCaption}>
                  {this.props.sending ? 'Sending...' : 'Send (⌘+Enter)'}
                </Text>
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
    flexDirection: 'row'
  },
  // ------------ channels
  channels: {
    width: 200,
  },
  channelScroll: {
    height: Dimensions.get('window').height // TODO: dynamic
  },
  channelScrollContainer: {
    //paddingHorizontal: 10
  },
  serverText: {
    color: '#666',
    paddingVertical: 5,
    paddingHorizontal: 6,
    fontSize: 12,
    fontWeight: '700'
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
    backgroundColor: 'white',
    //padding: 5,
    flexDirection: 'row'
  },
  input: {
    height: 70,
    width: 700, // TODO: dynamic
    backgroundColor: 'white',
    flex: 1,
    fontSize: 18,
    padding: 15,
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
    flex: 1,
    backgroundColor: 'white',
    top: 0,
  },
  messagesScrollContainer: {
    height: Dimensions.get('window').height - 150,
  },
  verticallyInverted: {
    transform: [
      { scaleY: 2 },
    ],
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
    fontFamily: 'Monaco'
    //fontSize: 12
  },
  messageUsername: {
    color: '#222',
    width: 100,
    textAlign: 'right',
    fontWeight: '600',
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
});
module.exports = ChatLayout;
