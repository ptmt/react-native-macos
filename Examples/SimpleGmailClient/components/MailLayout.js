/* @flow */
'use strict';

var React = require('react-native-desktop');
var {
  View,
  StyleSheet,
  ScrollView,
  Dimensions,
  Text,
  ActivityIndicatorIOS
} = React;

var SearchBox = require('./SearchBox');
var Message = require('./Message');
var Label = require('./Label');


class MailLayout extends React.Component {
  constructor() {
    super();
    this.state = {
      labels: [],
      selectedLabel: 'INBOX',
      loading: true
    };
  }
  componentDidMount() {
    this.fetchLabels();
    this.fetchMessages();
  }

  fetchLabels() {
    fetch('https://www.googleapis.com/gmail/v1/users/me/labels?access_token=' + this.props.access_token)
      .then(r => r.json())
      .then(r => {
        if (r.error) {
          this.props.onError(); // TODO:
        }
        this.setState({labels: r.labels});
      });
  }

  fetchMessages() {
    this.setState({loading: true});
    fetch('https://www.googleapis.com/gmail/v1/users/me/messages?labelIds=' + this.state.selectedLabel + '&includeSpamTrash=true&access_token=' + this.props.access_token)
      .then(r => r.json())
      .then(r => {
        this.setState({messages: r.messages, loading: false});
      });
  }

  render() {
    var labels = this.state.labels &&
      this.state.labels
      .filter(l => l.labelListVisibility && l.labelListVisibility === 'labelShow')
      .map(label =>
        <Label {...label}
          key={label.id}
          access_token={this.props.access_token} // TODO: move to external service / redux
          onSelect={(selectedLabel) => {
              this.setState({selectedLabel});
              this.fetchMessages();
          }}
          isSelected={label.name === this.state.selectedLabel} />);
    var messages = this.state.messages &&
      this.state.messages
      .map(message => <Message {...message} key={message.id} access_token={this.props.access_token} />);
    return (
      <View style={styles.container}>
        <View style={styles.labels}>
          {labels}
        </View>
        <View style={styles.messages}>
          <SearchBox />
          <ScrollView>
            {messages || <Text style={styles.notification}>No new mail!</Text>}
          </ScrollView>
        </View>
        <ActivityIndicatorIOS animating={this.state.loading} size={'large'} style={styles.spinner}/>
      </View>
    );
  }

}

var styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'white',

  },
  labels: {
    width: 300,
    padding: 30,
    // borderRightColor: '#ccc',
    // borderRightWidth: 1,
    height: Dimensions.get('window').height // TODO: dynamic
  },
  button: {
    margin: 10,
    backgroundColor: '#009aff',
    paddingVertical: 10,
    width: 250,
  },
  buttonCaption: {
    textAlign: 'center', color: 'white', fontSize: 20
  },
  messages: {
    position: 'absolute',
    flex: 1,
    top: 10,
    left: 300,
    height: Dimensions.get('window').height // TODO: dynamic
    //backgroundColor: '#ccc'
  },
  notification: {
    marginLeft: 20
  },
  textinput: {
    height: 30,
    borderWidth: 0.5,
    borderColor: '#0f0f0f',
    width: 450,
    fontSize: 16,
    padding: 4,
  },
  spinner: {
    position: 'absolute',
    top: 10,
    left: 200
  }
});
module.exports = MailLayout;
