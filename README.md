## React Native Desktop

Build OS X desktop apps using React Native.

[![Build Status](https://travis-ci.org/ptmt/react-native-desktop.svg)](https://travis-ci.org/ptmt/react-native-desktop)
[![npm version](https://badge.fury.io/js/react-native-desktop.svg)](https://badge.fury.io/js/react-native-desktop)

## TL;DR

<img width="914" alt="screenshot 2015-11-03 10 42 56" src="https://cloud.githubusercontent.com/assets/1004115/10905298/8c4e31bc-8219-11e5-8375-d43066e51c66.png">
*(Here goes a nice video demonstrating effective and smooth updates of native NSView tree from JS thread)*

**It's not production ready**: the lack of most important features, documentation is missing, there are no benchmarks and completed examples. It's also only for OS X at the moment.

Since it's a fork of React Native, you could follow the same steps to run Examples or your own app. Do not hesitate to ask on `#react-native-desktop` channel if you run into problems (and you will).

**Why not vanilla AppKit?**

- "Learn once, write anywhere" (c). Write low-level parts in Objective-C and use the power of React ecosystem.
- ClojureScript, Elm, Whatever-to-js-compiles.
- Developer experience, especially for the UI-part.

**Why not Electron?**

- In some ways RND is kind of a small unstable subset of Electron's features: there is no DOM, CSS, browser APIs. Potentially it could be useful if you don't need a whole browser for your app. Until the next-gen parallel browser engines become real.
- RND's footprint is relatively small (about 1.3MB for Examples/SimpleChatClient) and could be configured.


****

If you are into React.js please help to make examples look clean and idiomatic. If you can give an advice on Windows or Linux bindings or just have an idea for an awesome app which you always wanted, please feel free to reach me out on `#react-native-desktop`.

Some screenshots:

![uiexplorer](https://cloud.githubusercontent.com/assets/1004115/10608147/311445b0-7757-11e5-9ef7-2e76107e4bb7.png)

<img width="986" alt="screenshot 2015-10-24 16 40 36" src="https://cloud.githubusercontent.com/assets/1004115/10710169/c1bc7d06-7a65-11e5-8bab-4f89ecae26c3.png">

<img width="986" alt="screenshot 2015-10-27 17 08 38" src="https://cloud.githubusercontent.com/assets/1004115/10756317/0ee807ec-7cc5-11e5-8fe4-6aaa8a9f7858.png">

<sup>*Codename "Lepton"*</sup>
