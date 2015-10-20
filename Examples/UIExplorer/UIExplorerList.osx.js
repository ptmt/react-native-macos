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
 * @flow
 */
'use strict';

var React = require('react-native-desktop');
var {
  AppRegistry,
  Settings,
  StyleSheet,
} = React;

var { TestModule } = React.addons;

import type { NavigationContext } from 'NavigationContext';

var UIExplorerListBase = require('./UIExplorerListBase');

var COMPONENTS = [
  require('./ActivityIndicatorIOSExample'),
  require('./DatePickerIOSExample'),
  // require('./ImageExample'),
  //require('./LayoutEventsExample'),
  //require('./ListViewExample'),
  // require('./ListViewGridLayoutExample'),
  // require('./ListViewPagingExample'),
  // require('./ModalExample'),
  // require('./PickerIOSExample'),
  require('./ProgressViewIOSExample'),
  require('./ScrollViewExample'),
  require('./SegmentedControlIOSExample'),
  require('./SliderIOSExample'),
  require('./SwitchIOSExample'),
  require('./TextExample.osx'),
  require('./TextInputExample.osx'),
  require('./TouchableExample'),
  require('./ViewExample'),
  require('./WebViewExample'),
];

var APIS = [
  // require('./AccessibilityIOSExample'),
  // require('./AlertIOSExample'),
  require('./AnimatedExample'),
  // require('./AnimatedGratuitousApp/AnExApp'),
  // require('./AppStateIOSExample'),
  // require('./AsyncStorageExample'),
  require('./BorderExample'),
  require('./LayoutExample'),
  // require('./NetInfoExample'),
  // require('./PanResponderExample'),
  // require('./PointerEventsExample'),
  // require('./PushNotificationIOSExample'),
  // require('./StatusBarIOSExample'),
  // require('./TimerExample'),
  // require('./VibrationIOSExample'),
  require('./XHRExample.osx'),

];

// Register suitable examples for snapshot tests
COMPONENTS.concat(APIS).forEach((Example) => {
  if (Example.displayName) {
    var Snapshotter = React.createClass({
      componentDidMount: function() {
        // View is still blank after first RAF :\
        global.requestAnimationFrame(() =>
          global.requestAnimationFrame(() => TestModule.verifySnapshot(
            TestModule.markTestPassed
          )
        ));
      },
      render: function() {
        var Renderable = UIExplorerListBase.makeRenderable(Example);
        return <Renderable />;
      },
    });
    AppRegistry.registerComponent(Example.displayName, () => Snapshotter);
  }
});

type Props = {
  openExample: Function,
};

class UIExplorerList extends React.Component {
  props: Props;

  render() {
    return (
      <UIExplorerListBase
        components={COMPONENTS}
        apis={APIS}
        searchText={Settings.get('searchText')}
        renderAdditionalView={this.renderAdditionalView.bind(this)}
        search={this.search.bind(this)}
        onPressRow={this.onPressRow.bind(this)}
      />
    );
  }

  renderAdditionalView(renderRow: Function, renderTextInput: Function): React.Component {
    return renderTextInput(styles.searchTextInput);
  }

  search(text: mixed) {
    Settings.set({searchText: text});
  }

  onPressRow(example: any) {
    var Component = UIExplorerListBase.makeRenderable(example);
    this.props.openExample(Component);
  }
}

var styles = StyleSheet.create({
  searchTextInput: {
    height: 30,
  },
});

module.exports = UIExplorerList;
