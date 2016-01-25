<<<<<<< HEAD
## React Native Desktop
=======
# React Native [![Build Status](https://travis-ci.org/facebook/react-native.svg?branch=master)](https://travis-ci.org/facebook/react-native) [![Circle CI](https://circleci.com/gh/facebook/react-native.svg?style=svg)](https://circleci.com/gh/facebook/react-native) [![npm version](https://badge.fury.io/js/react-native.svg)](http://badge.fury.io/js/react-native)
>>>>>>> ae45d8bd4cc7b0fc810c3f21dcf2c7188ae3097d

Build OS X desktop apps using React Native.

[![Build Status](https://travis-ci.org/ptmt/react-native-desktop.svg)](https://travis-ci.org/ptmt/react-native-desktop)
[![npm version](https://badge.fury.io/js/react-native-desktop.svg)](https://badge.fury.io/js/react-native-desktop)
[![discord #react-native-desktop](https://img.shields.io/badge/discord-%23react--native--desktop-blue.svg)](https://discordapp.com/channels/102860784329052160/111514927801307136)

<<<<<<< HEAD
[![Youtube play](https://cloud.githubusercontent.com/assets/1004115/11685246/75db9d6a-9e99-11e5-8378-1d5cea6053c0.png)](https://www.youtube.com/watch?v=m1-LNKIuqtI)
=======
- [Getting Started](#getting-started)
- [Getting Help](#getting-help)
- [Documentation](#documentation)
- [Examples](#examples)
- [Extending React Native](#extending-react-native)
- [Upgrading](#upgrading)
- [Opening Issues](#opening-issues)
- [Contributing](#contributing)
- [License](#license)
>>>>>>> ae45d8bd4cc7b0fc810c3f21dcf2c7188ae3097d

**It's not a production-ready yet**

## Getting started

<<<<<<< HEAD
=======
## Getting Started

- Follow the [Getting Started guide](http://facebook.github.io/react-native/docs/getting-started.html) to install React Native and its dependencies.
- Check out this [tutorial](https://facebook.github.io/react-native/docs/tutorial.html) to walk through your first project that fetches real data and displays it in a list.
- [Open the UIExplorer example project](#examples) to see a list of components that ship with React Native.
- Install the React Developer Tools for [Chrome](https://chrome.google.com/webstore/detail/react-developer-tools/fmkadmapgofadopljbjfkapdkoienihi) or [Firefox](https://addons.mozilla.org/en-US/firefox/addon/react-devtools/) for better debugging [(read more)](http://facebook.github.io/react-native/docs/debugging.html).
- Try out apps from the [Showcase](https://facebook.github.io/react-native/showcase.html) to see what React Native is capable of!

## Getting Help

Please use these community resources for getting help. We use the GitHub issues for tracking bugs and feature requests and have limited bandwidth to address them.

- Ask a question on [StackOverflow](http://stackoverflow.com/) and tag it with `react-native`
- Chat with us on [Reactiflux](https://discord.gg/0ZcbPKXt5bWJVmUY) in #react-native
- Articulate your feature request or upvote existing ones on [Product Pains](https://productpains.com/product/react-native/)
- Start a thread on the [React Discussion Board](https://discuss.reactjs.org/)
- Join #reactnative on IRC: chat.freenode.net
- If it turns out that you may have found a bug, please [open an issue](#opening-issues)

## Documentation

[The website’s documentation](https://facebook.github.io/react-native/docs/) is divided into multiple sections.
- There are **Guides** that discuss topics like [debugging](https://facebook.github.io/react-native/docs/debugging.html), [integrating with existing apps](https://facebook.github.io/react-native/docs/embedded-app-ios.html), and [the gesture responder system](https://facebook.github.io/react-native/docs/gesture-responder-system.html).
- The **Components** section covers React components such as [`View`](https://facebook.github.io/react-native/docs/view.html) and [`Navigator`](https://facebook.github.io/react-native/docs/navigator.html).
- The **APIs** section covers other libraries like [Animated](https://facebook.github.io/react-native/docs/animated.html) and [StyleSheet](https://facebook.github.io/react-native/docs/stylesheet.html) that aren’t React components themselves.
- Finally, React Native provides a small number of **Polyfills** that offer web-like APIs.

Another great way to learn more about the components and APIs included with React Native is to read their source. Look under the `Libraries` directory for components like `ScrollView` and `Navigator`, for example. The UIExplorer example is also here to demonstrate some of the ways to use these components. From the source you can get an accurate understanding of each component’s behavior and API.

The React Native documentation only discusses the components, APIs and topics specific to React Native (React on iOS and Android). For further documentation on the React API that is shared between React Native and React DOM, refer to the [React documentation](http://facebook.github.io/react/).

## Examples

- `git clone https://github.com/facebook/react-native.git`
- `cd react-native && npm install`

### Running the examples on iOS

Now open any example (the `.xcodeproj` file in each of the `Examples` subdirectories) and hit Run in Xcode.

### Running the examples on Android

Note that you'll need the Android NDK installed, see [prerequisites](https://github.com/facebook/react-native/blob/master/ReactAndroid/README.md#prerequisites).

```bash
./gradlew :Examples:Movies:android:app:installDebug
# Start the packager in a separate shell (make sure you ran npm install):
./packager/packager.sh
# Open the Movies app in your emulator
>>>>>>> ae45d8bd4cc7b0fc810c3f21dcf2c7188ae3097d
```
npm install react-native-desktop-cli -g
cd projects
react-native-desktop init MyProject
```
Since it's simply a fork of React Native, basically you just can follow [the same steps](http://facebook.github.io/react-native/docs/getting-started.html#content).
Feel free to ask anything on `#react-native-desktop` channel if you run into problems (and you probably will).

<<<<<<< HEAD
****

If you are into React.js please help to make examples look clean and idiomatic. If you can give an advice on Windows or Linux bindings or just have an idea for an awesome app which you always wanted, please feel free to reach me out on `#react-native-desktop`.
=======
## Extending React Native

- Looking for a component? [JS.coach](https://js.coach/react-native)
- Fellow developers write and publish React Native modules to npm and open source them on GitHub.
- Making modules helps grow the React Native ecosystem and community. We recommend writing modules for your use cases and sharing them on npm.
- Read the guides on Native Modules ([iOS](http://facebook.github.io/react-native/docs/native-modules-ios.html), [Android](http://facebook.github.io/react-native/docs/native-modules-android.html)) and Native UI Components ([iOS](http://facebook.github.io/react-native/docs/native-components-ios.html), [Android](http://facebook.github.io/react-native/docs/native-components-android.html)) if you are interested in extending native functionality.

## Upgrading

React Native is under active development. See the guide on [upgrading React Native](https://facebook.github.io/react-native/docs/upgrading.html) to keep your project up-to-date.

## Opening Issues

If you encounter a bug with React Native we would like to hear about it. Search the [existing issues](https://github.com/facebook/react-native/issues) and try to make sure your problem doesn’t already exist before opening a new issue. It’s helpful if you include the version of React Native and OS you’re using. Please include a stack trace and reduced repro case when appropriate, too.

The GitHub issues are intended for bug reports and feature requests. For help and questions with using React Native please make use of the resources listed in the [Getting Help](#getting-help) section. [Product Pains](https://productpains.com/product/react-native/) in particular is a good way to signal your interest in a feature or issue. There are limited resources available for handling issues and by keeping the list of open issues lean we can respond in a timely manner.

## Contributing

For more information about contributing PRs and issues, see our [Contribution Guidelines](https://github.com/facebook/react-native/blob/master/CONTRIBUTING.md).

[Good First Task](https://github.com/facebook/react-native/labels/Good%20First%20Task) is a great starting point for PRs.

We encourage the community to ask and answer questions on Stack Overflow with [the react-native tag](https://stackoverflow.com/questions/tagged/react-native). It's a great way to help out and be involved!
>>>>>>> ae45d8bd4cc7b0fc810c3f21dcf2c7188ae3097d

UIExplorer screenshots:

![uiexplorer](https://cloud.githubusercontent.com/assets/1004115/10608147/311445b0-7757-11e5-9ef7-2e76107e4bb7.png)

<img width="986" alt="screenshot 2015-10-24 16 40 36" src="https://cloud.githubusercontent.com/assets/1004115/10710169/c1bc7d06-7a65-11e5-8bab-4f89ecae26c3.png">

<img width="986" alt="screenshot 2015-10-27 17 08 38" src="https://cloud.githubusercontent.com/assets/1004115/10756317/0ee807ec-7cc5-11e5-8fe4-6aaa8a9f7858.png">
