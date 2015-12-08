/* @flow */
'use strict';

import React,  {
  Text,
  StyleSheet,
  ListView
} from 'react-native-desktop';

import Message from './Message';

const ds = new ListView.DataSource({rowHasChanged: (r1, r2) => r1.id !== r2.id});

export default class MessagesListView extends React.Component {

  constructor(props: any) {
    super(props);
    this.state = {
      dataSource: props.messages ? ds.cloneWithRows(props.messages) : ds.cloneWithRows([])
    };
  }

  componentWillReceiveProps(nextProps: any) {
    this.setState({
      dataSource: nextProps.messages ? ds.cloneWithRows(nextProps.messages) : ds.cloneWithRows([])
    });
  }
  render() {
    return (
      <ListView
        style={styles.container}
        initialListSize={20}
        dataSource={this.state.dataSource}
        renderRow={(message, s, i) => this.renderRow(message, i)}
        autoScrollToBottom={true}
        showsVerticalScrollIndicator={true}
      />
    );
  }

  renderRow(message: any, i: number) {
    return <Message {...message} key={i} />;
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    // marginTop: 100,
    // alignItems: 'center',
    // justifyContent: 'center'
  }
});
