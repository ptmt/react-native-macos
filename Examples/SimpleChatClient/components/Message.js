/* @flow */
'use strict';

import React,  {
  View,
  Text,
  Image,
  StyleSheet
} from 'react-native-desktop';

import Markdown from './SuperSimpleMarkdown';

export default class Message extends React.Component {
  render() {
    const date = new Date(this.props.timestamp);
    const time = ('0' + date.getHours()).slice(-2) + ':' +   ('0' + date.getMinutes()).slice(-2);
    const attachedImage = this.props.attachments && this.props.attachments.length > 0 && this.props.attachments[0].url ?
      this.props.attachments[0].url : null;

    const attachedEmbeds =  this.props.embeds && this.props.embeds.length > 0 && this.props.embeds[0].thumbnail ?
      this.props.embeds[0] : null;

    return (
      <View style={[styles.message]} key={this.props.id}>
        <Text style={styles.messageTimestamp}>{time}</Text>
        <Text style={styles.messageUsername} numberOfLines={1}>{'<'}{this.props.author.username}{'>'}</Text>
        {attachedImage &&
          <Image resizeMode={'contain'} source={{uri: attachedImage}} style={{width: 300, height: 300}} />
        }
        <Markdown>{parseMentions(this.props.content, this.props.mentions)}</Markdown>
        {attachedEmbeds &&
          <Preview {...attachedEmbeds} />
        }
      </View>
    );
  } //
}

class Preview extends React.Component {
  render() {
    return (
      <View style={{flex: 1, margin: 10, borderColor: '#eee', borderWidth: 1, padding: 3}}>
        <Text style={{fontSize: 12, textAlign:'center', fontWeight: 'bold'}}>{this.props.title}</Text>
        <View style={{flexDirection: 'row', flex: 1, justifyContent: 'center', alignContent: 'center'}}>
          <Image resizeMode={'contain'} source={{uri: this.props.thumbnail.url}} style={{margin: 5, width: 80, height: 80}} />
          <Text style={{fontSize: 12, color: '#777', margin: 10, width: 200}}>{this.props.description}</Text>
        </View>
      </View>
    );
  }
}

function parseMentions(text: string, mentions: Array<any>): string {
  if (!mentions || mentions.length === 0 || !text) {
    return text;
  }
  const matches = text.match(/<@[^>]*>/g);
  if (!matches) {
    return text;
  }
  matches.forEach(mention => {
    const id = mention.substring(2, mention.length - 1);
    // TODO: ignore links
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
