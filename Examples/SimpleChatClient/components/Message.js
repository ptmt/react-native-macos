/* @flow */
'use strict';

import React,  {
  View,
  Text,
  Image,
  StyleSheet,
  Animated
} from 'react-native-desktop';

import Markdown from './SuperSimpleMarkdown';

export default class Message extends React.Component {
  render(): ReactElement {
    const date = new Date(this.props.timestamp);
    const time = ('0' + date.getHours()).slice(-2) + ':' +   ('0' + date.getMinutes()).slice(-2);
    const attachImage = this.props.attachments && this.props.attachments.length > 0 ?
      this.props.attachments[0].url : null;
    return (
      <View style={[styles.message]} key={this.props.id}>
        <Text style={styles.messageTimestamp}>{time}</Text>
        <Text style={styles.messageUsername} numberOfLines={1}>{'<'}{this.props.author.username}{'>'}</Text>
        {attachImage &&
          <Image resizeMode={'contain'} source={{uri: attachImage}} style={{width: 300, height: 300}} />
        }
        <Markdown>{parseMentions(this.props.content, this.props.mentions)}</Markdown>
      </View>
    );
  }
}

function parseMentions(text: string, mentions: Array<any>): string {
  if (!mentions || mentions.length === 0) {
    return text;
  }
  const matches = text.match(/<@[^>]*>/g);
  matches.forEach(mention => {
    const id = mention.substring(2, mention.length - 1);
		text = text.replace(mention, '**@' + mentions.filter(m => m.id === id)[0].username + '**');
  });
  return text;
}

const styles = StyleSheet.create({
  message: {
    flex: 1,
    flexDirection: 'row',
    marginLeft: 10,
    marginBottom: 5,
  },
  messageTimestamp: {
    color: '#999',
    marginRight: 5,
    fontFamily: 'Monaco',
    fontSize: 12,
  },
  messageUsername: {
    color: '#222',
    width: 100,
    fontSize: 12,
    textAlign: 'right',
    fontWeight: '600',
  },
  messageText: {
    color: '#222',
    marginLeft: 4,
    fontSize: 12,
  }
});
