# React Native macOS (ex react-native-desktop)

Build macOS desktop applications using React Native.

----

**Warning**. As Apple announced Project Catalyst it does make sense to use just original React Native with macOS target. There is some chance that this project is no longer needed.

----

[![Build Status](https://travis-ci.org/ptmt/react-native-macos.svg)](https://travis-ci.org/ptmt/react-native-macos) [![npm version](https://badge.fury.io/js/react-native-macos.svg)](https://badge.fury.io/js/react-native-macos) [![discord #react-native-platforms](https://img.shields.io/badge/reactiflux-%23react--native--platforms-blue.svg)](http://reactiflux.com)

```jsx
<View>
  <Button onPress={() => alert('clicked!')} />
</View>
```

## Getting Started

Node 4.x+, OS X 10.11+ required.

_Previous React Native experience is highly recommended_.

```bash
$ npm install react-native-macos-cli -g
$ react-native-macos init MyProject
$ cd MyProject
$ react-native-macos run-macos
```

If you want to add macOS target to the existing iOS/Android/Windows project, make the steps above, merge this new folder into your current React Native project, then put [rn-cli.config.js](https://gist.github.com/ptmt/b1473dead098cf53d667e355aedf2a7b) in the root.

## Documentation

Since React Native macOS is just a fork, you can follow [the same instructions on the React Native Documentation](http://facebook.github.io/react-native/docs/getting-started.html#content).

## Disclaimer

React Native macOS is a fork of React Native for iOS. The project is still a fairly new so proceed at your own risk.

## Community Help

Please use these community resources for getting help. We use the GitHub issues for tracking bugs and feature requests and have limited bandwidth to address them.

- Ask a question on [StackOverflow](https://stackoverflow.com/) and tag it with `react-native-macos`
- Chat with us on [Reactiflux](https://discord.gg/0ZcbPKXt5bWJVmUY) in `#react-native-platforms` (mentioning @ptmt)
- DM @ptmt on twitter

## Examples

### RNTesterApp

RNTesterApp includes a set of component examples that illustrate their functionality. It also allows you to load external JavaScript bundle files through HTTP. Just copy and paste a URL into the Search Field.

[Download UIExplorer](https://github.com/ptmt/react-native-macos/files/199128/UIExplorer.zip)

![screenshot 2016-03-31 21 06 33](https://cloud.githubusercontent.com/assets/1004115/14185918/91648d8c-f784-11e5-82b6-fcd08b74b89a.png)

![screenshot 2016-03-31 21 00 30](https://cloud.githubusercontent.com/assets/1004115/14185806/1cd2dfdc-f784-11e5-8c14-de0ca21f7ead.png)

![screenshot 2015-10-24 16 40 36](https://cloud.githubusercontent.com/assets/1004115/14185895/7c133eb0-f784-11e5-8e3c-ca36aa351a26.png)

## License

React Native is MIT licensed.
