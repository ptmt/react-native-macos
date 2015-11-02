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
  TouchableHighlight,
  LinkingIOS,
  Image,
  Dimensions
} = React;

const AnimatedButton = Animated.createAnimatedComponent(TouchableHighlight);

class SigninForm extends React.Component {
  constructor() {
    super();
    this.state = {
      scale: new Animated.Value(2.0),
      rotate: new Animated.Value(0.5),
      x: new Animated.Value(0),
      animatedColor: new Animated.Value(0)
    };
  }
  componentDidMount() {
    Animated.sequence([
      Animated.delay(400),
      Animated.spring(this.state.scale, {
        toValue: 1
      })
    ]).start();
  }
  componentWillReceiveProps(nextProps: any) {
    if (nextProps.isLoading && !this.props.isLoading) {
      this.pulse(false);
    }
    if (nextProps.error) {
      this.onError();
    }
  }
  pulse(back: boolean) {
    Animated.timing(this.state.animatedColor, {
      toValue: back ? 0 : 1,
      duration: 1000
    }).start(() => {
      if (this.props.isLoading) {
        setTimeout(() => this.pulse(!back), 500);
      }
    });
  }
  onError() {
    this.state.x.setValue(0)
    Animated.spring(this.state.x, {
      toValue: 1,
      friction: 5,
      tension: 300
    }).start();
  }
  render() {
    const animatedScale = {transform: [
      {
        scale: this.state.scale,
      }
    ], left: this.state.x.interpolate({
       inputRange: [0, 0.5, 1],
       outputRange: [0, 20, 0]  // 0 : 150, 0.5 : 75, 1 : 0
     })};

    const rand = () => Math.floor(Math.random() * 255);
    const fromColors = [1, 2, 3].map(c => rand()).join(', ');
    const toColors = [1, 2, 3].map(c => rand()).join(', ');
    const animatedColor = this.state.animatedColor.interpolate({
        inputRange: [0, 1],
        outputRange: [
          'rgb(' + fromColors.toString() + ')',
          'rgb(' + toColors.toString() + ')'
        ]
    });

    return (
      <Image style={styles.container}
        source={{uri: 'https://images.unsplash.com/photo-1444703686981-a3abbc4d4fe3?dpr=2&fit=crop&fm=jpg&h=825&ixlib=rb-0.3.5&q=50&w=1450'}}
        resizeMode={Image.resizeMode.cover}>
        <Animated.View style={[styles.form, animatedScale]}>
          <Text style={styles.header}>Simple Chat Client</Text>
          <View style={styles.input}>
            <Text style={styles.placeholder}>EMAIL</Text>
            <TextInput
              style={styles.textinput}
              multiline={false}
              onChangeText={(username) => this.setState({username})}
            />
          </View>
          <View style={styles.input}>
            <Text style={styles.placeholder}>PASSWORD</Text>
            <TextInput
              style={styles.textinput}
              multiline={false}
              password={true}
              onChangeText={(password) => this.setState({password})}
            />
          </View>
          <AnimatedButton
            style={[styles.button, this.props.isLoading ? {backgroundColor: animatedColor} : {}]}
            onPress={() => this.props.login(this.state.username, this.state.password)}
          >
            <Text style={styles.buttonCaption}>Login</Text>
          </AnimatedButton>
        </Animated.View>
        <View style={styles.footer}>
          <Text style={styles.footerText}>This app uses Discord unofficial APIs only for demonstration purposes.</Text>
        </View>
      </Image>
    );
  }

}

var styles = StyleSheet.create({
  container: {
    justifyContent: 'center',
    alignItems: 'center',
    flex: 1,
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
    color: '#333',
    marginBottom: 20
  },
  button: {
    marginVertical: 20,
    backgroundColor: '#009aff',
    paddingVertical: 10,
    width: 250,
  },
  buttonCaption: {textAlign: 'center', color: 'white', fontSize: 20},
  textinput: {
    height: 25,
    borderWidth: 0,
    borderColor: '#0f0f0f',
    width: 250,
    fontSize: 16,
    //padding: 6,
  },
  input: {
    borderBottomWidth: 1,
    borderBottomColor: '#ccc',
    marginBottom: 20
  },
  placeholder: {
    color: '#999',
    marginBottom: 5
  },
  footer: {
    position: 'absolute',
    flex: 1,
    marginLeft: 50,
    top: 10 //TODO: why so? weird
  },
  footerText: {
    fontSize: 10,
    color: 'white'
  }
});
module.exports = SigninForm;
