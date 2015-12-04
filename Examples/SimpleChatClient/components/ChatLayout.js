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
import MessagesListView from './MessagesListView';

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

    const messages = this.props.messages;

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
            <View style={{flex: 1}}>
              {messages && messages.length > 0 ?
                <MessagesListView messages={messages} /> :
                <LoadingIndicator visible={messages}>Loading messages...</LoadingIndicator>
              }
            </View>
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
    backgroundColor: 'white'
  },
  messagesScrollContainer: {
    height: Dimensions.get('window').height - 150,
  },
});
module.exports = ChatLayout;
