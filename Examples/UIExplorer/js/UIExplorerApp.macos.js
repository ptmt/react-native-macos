/**
 * The examples provided by Facebook are for non-commercial testing and
 * evaluation purposes only.
 *
 * Facebook reserves all rights not expressly granted.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NON INFRINGEMENT. IN NO EVENT SHALL
 * FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
 * AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * @providesModule UIExplorerApp
 * @flow
 */
'use strict';

import React from 'React';
import ReactNative from 'react-native';
import { UIExplorerList } from './UIExplorerList.macos';

const {
  AppRegistry,
  // SnapshotViewIOS,
  StyleSheet,
  View,
  Text,
  Dimensions,
} = ReactNative;

const defaultLayout = Dimensions.get('window');

class UIExplorerApp extends React.Component {
  state: any;
  constructor() {
    super();
    this.state = {
      component: Welcome, //UIExplorerListBase.makeRenderable(BorderExample)
      layout: defaultLayout,
    };
  }

  render() {
    var Component = this.state.component;
    return (
      <View
        style={styles.container}
        onLayout={e => this.setState({ layout: e.nativeEvent.layout })}>
        <View style={[styles.leftPanel, { width: 300 }]}>
          <UIExplorerList
            openExample={component => this.setState({ component })}
          />
        </View>
        <View
          style={[styles.rightPanel, { width: this.state.layout.width - 300 }]}
          respondsToLiveResizing>
          {this.state.component && <Component />}
        </View>
      </View>
    );
  }
}

class Welcome extends React.Component {
  render() {
    return (
      <View style={styles.welcomeWrapper}>
        <Text style={styles.welcomeText}>
          Choose an example on the left side
        </Text>
      </View>
    );
  }
}

var styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'row',
  },
  itemWrapper: {
    backgroundColor: '#eaeaea',
  },
  leftPanel: {
    width: 300,
  },
  rightPanel: {
    flex: 1,
    backgroundColor: '#fff',
  },
  welcomeWrapper: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  welcomeText: {
    color: '#999',
    fontSize: 20,
  },
});

AppRegistry.registerComponent('UIExplorerApp', () => UIExplorerApp);
AppRegistry.registerComponent('SetPropertiesExampleApp', () =>
  require('./SetPropertiesExampleApp')
);
AppRegistry.registerComponent('RootViewSizeFlexibilityExampleApp', () =>
  require('./RootViewSizeFlexibilityExampleApp')
);

module.exports = UIExplorerApp;
