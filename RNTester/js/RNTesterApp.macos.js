/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 *
 * @providesModule RNTesterApp
 * @flow
 */
'use strict';

const AsyncStorage = require('AsyncStorage');
const Linking = require('Linking');
const React = require('react');
const ReactNative = require('react-native');
const RNTesterActions = require('./RNTesterActions');
const RNTesterExampleContainer = require('./RNTesterExampleContainer');
const RNTesterExampleList = require('./RNTesterExampleList');
const RNTesterList = require('./RNTesterList.macos');
const RNTesterNavigationReducer = require('./RNTesterNavigationReducer');
const URIActionMap = require('./URIActionMap');

import { AppearanceConsumer } from './AppearanceContext';


const {
  AppRegistry,
  SnapshotViewIOS,
  StyleSheet,
  View,
  Text,
  Appearance,
} = ReactNative;

import type { RNTesterExample } from './RNTesterList.ios';
import type { RNTesterAction } from './RNTesterActions';
import type { RNTesterNavigationState } from './RNTesterNavigationReducer';

type Props = {
  exampleFromAppetizeParams: string,
};

const APP_STATE_KEY = 'RNTesterAppState.v2';

class RNTesterApp extends React.Component<Props, RNTesterNavigationState> {
  state = {}
  componentDidMount() {
    Linking.getInitialURL().then((url) => {
      AsyncStorage.getItem(APP_STATE_KEY, (err, storedString) => {
        const exampleAction = URIActionMap(this.props.exampleFromAppetizeParams);
        const urlAction = URIActionMap(url);
        const launchAction = exampleAction || urlAction;
        if (err || !storedString) {
          const initialAction = launchAction || {type: 'InitialAction'};
          this.setState(RNTesterNavigationReducer(undefined, initialAction));
          return;
        }
        const storedState = JSON.parse(storedString);
        if (launchAction) {
          this.setState(RNTesterNavigationReducer(storedState, launchAction));
          return;
        }
        this.setState(storedState);
      });
    });

    Linking.addEventListener('url', (url) => {
      this._handleAction(URIActionMap(url));
    });
  }

  _handleBack = () => {
    this._handleAction(RNTesterActions.Back());
  }

  _handleAction = (action: ?RNTesterAction) => {
    if (!action) {
      return;
    }
    const newState = RNTesterNavigationReducer(this.state, action);
    if (this.state !== newState) {
      this.setState(
        newState,
        () => AsyncStorage.setItem(APP_STATE_KEY, JSON.stringify(this.state))
      );
    }
  }

  renderInnerComponent() {
    if (this.state.openExample) {
      const Component = RNTesterList.Modules[this.state.openExample];
      if (Component.external) {
        return (
          <Component
            onExampleExit={this._handleBack}
          />
        );
      } else {
        return (
            <RNTesterExampleContainer module={Component} />
        );
      }
    }
    return <Welcome />;
  }

  render() {
    return (
      <View
        style={styles.container}>
        <View style={[styles.leftPanel, { width: '30%' }]}>
          <RNTesterExampleList
            onNavigate={this._handleAction}
            list={RNTesterList}
            openExample={this.state.openExample}
          />
        </View>
        <View
          style={[styles.rightPanel]}
          >
          {this.renderInnerComponent()}
        </View>
      </View>

    );
  }
}


class Welcome extends React.Component<{}> {
  render() {
    return (
      <AppearanceConsumer>
        {appearance => ( 
          <View style={[styles.welcomeWrapper, { backgroundColor: appearance.colors.windowBackgroundColor }]}>
            <Text style={styles.welcomeText}>
              Choose an example on the left side
            </Text>
          </View>
        )}
      </AppearanceConsumer>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'row',
  },
  leftPanel: {
    width: 300,
  },
  rightPanel: {
    flex: 1,
    width: '100%',
  },
  welcomeWrapper: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  welcomeText: {
    color: '#999',
    fontSize: 18,
  },
});

AppRegistry.registerComponent('SetPropertiesExampleApp', () => require('./SetPropertiesExampleApp'));
AppRegistry.registerComponent('RootViewSizeFlexibilityExampleApp', () => require('./RootViewSizeFlexibilityExampleApp'));
AppRegistry.registerComponent('RNTesterApp', () => RNTesterApp);

// Register suitable examples for snapshot tests
RNTesterList.ComponentExamples.concat(RNTesterList.APIExamples).forEach((Example: RNTesterExample) => {
  const ExampleModule = Example.module;
  if (ExampleModule.displayName) {
    class Snapshotter extends React.Component<{}> {
      render() {
        return (
          <SnapshotViewIOS>
            <RNTesterExampleContainer module={ExampleModule} />
          </SnapshotViewIOS>
        );
      }
    }

    AppRegistry.registerComponent(ExampleModule.displayName, () => Snapshotter);
  }
});

module.exports = RNTesterApp;
