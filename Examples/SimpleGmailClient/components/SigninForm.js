/* @flow */
'use strict';

var React = require('react-native-desktop');
var {
  View,
  Text,
  Animated,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  LinkingIOS
} = React;

// Yes this is my api credentials restricted only for Gmail API.
var CLIENT_ID = '588257598045-mlcll7rfg8vud8glu411f8v92u560pbt.apps.googleusercontent.com';
var CLIENT_SECRET = 'q6M4ZwP_qlZ5IqQoi4tGzLdQ';
var AUTH_URL = 'https://accounts.google.com/o/oauth2/auth?scope=email%20profile%20https://www.googleapis.com/auth/gmail.readonly&redirect_uri=urn:ietf:wg:oauth:2.0:oob&response_type=code&client_id=' + CLIENT_ID;

class SigninForm extends React.Component {
  constructor() {
    super();
    this.state = {
      scale: new Animated.Value(0),
      rotate: new Animated.Value(0.5)
    };
  }
  componentDidMount() {
    Animated.spring(this.state.scale, {
      toValue: 1,
      friction: 3
    }).start();
  }
  obtainToken(code: string) {
    this.pulse(true);
    var data = ['client_id=' + CLIENT_ID,
      'client_secret=' + CLIENT_SECRET,
      'code=' + code,
      'grant_type=authorization_code',
      'redirect_uri=urn:ietf:wg:oauth:2.0:oob'
    ].join('&');
    fetch('https://www.googleapis.com//oauth2/v3/token', {
        method: 'POST',
        body: data
      })
      .then(r => r.json())
      .then(json => {
        this.setState({
          loading: false
        });
        this.props.onSignin(json);
      })
      .catch(e => console.log(e));
  }
  pulse(back: boolean) {
    Animated.spring(this.state.scale, {
      toValue: back ? 0.98 : 1
    }).start(() => {
      if (this.state.loading) {
        setTimeout(() => this.pulse(!back), 500);
      }
    });
  }
  hide() {
    Animated.spring(this.state.scale, {
      toValue: 0
    }).start(() => this.props.onSignin(this.state.token));
  }
  render() {
    var animatedScale = {transform: [
      {
        scale: this.state.scale
      }
    ]};
    return (
      <View style={styles.container}>
        <Animated.View style={[styles.form, animatedScale]}>
          <Text style={styles.header}>Simple Gmail Client</Text>
          <TouchableOpacity onPress={()=> LinkingIOS.openURL(AUTH_URL)}>
          <Text>Click here to open Google Accounts</Text>
          </TouchableOpacity>
          <Text style={styles.content}>Then paste token from success page:</Text>
          <View style={{marginTop: 30}}>
            <TextInput
              placeholder={'oAuth client token'}
              style={styles.textinput}
              onChangeText={(code) => this.setState({code})}
            />
          </View>
          <TouchableOpacity style={styles.button} onPress={() => this.obtainToken(this.state.code)}>
            <Text style={styles.buttonCaption} multiline={false}>Sign in</Text>
          </TouchableOpacity>
        </Animated.View>
      </View>
    );
  }

}

var styles = StyleSheet.create({
  container: {
    justifyContent: 'center',
    alignItems: 'center',
    flex: 1
  },
  content: {
    width: 300,
    margin: 10,
    color: '#888',
    textAlign: 'center'
  },
  form: {
    padding: 20,
    backgroundColor: 'white',
    justifyContent: 'center',
    alignItems: 'center',
    borderColor: '#bbb',
    borderWidth: 1
  },
  header: {
    fontSize: 30,
    color: '#999',
    marginBottom: 50
  },
  button: {
    margin: 10,
    backgroundColor: '#009aff',
    paddingVertical: 10,
    width: 250,
  },
  buttonCaption: {textAlign: 'center', color: 'white', fontSize: 20},
  textinput: {
    height: 30,
    borderWidth: 0.5,
    borderColor: '#0f0f0f',
    width: 250,
    fontSize: 10,
    padding: 4,
  },
});
module.exports = SigninForm;
