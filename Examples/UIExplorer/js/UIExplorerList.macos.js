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

const React = require('react');
const ReactNative = require('react-native');
const { AppRegistry, Settings, SnapshotViewIOS, StyleSheet } = ReactNative;

const UIExplorerListBase = require('./UIExplorerListBase');

export const Components = [
  require('./ActivityIndicatorExample'),
  require('./ButtonExample'),
  require('./DatePickerIOSExample'),
  require('./ImageExample'),
  require('./LayoutEventsExample'),
  require('./ListViewExample'),
  // require('./ListViewGridLayoutExample'),
  // require('./ListViewPagingExample'),
  require('./ModalExample'),
  require('./ProgressViewIOSExample'),
  require('./ScrollViewExample'),
  // require('./SegmentedControlIOSExample'),
  require('./SliderExample'),
  //require('./SwitchExample'),
  require('./TextExample.macos'),
  require('./TextInputExample.macos'),
  require('./TouchableExample'),
  require('./TransparentHitTestExample'),
  require('./ViewExample'),
  require('./WebViewExample'),
  require('./ReactARTExample'),
];

var APIS = [
  require('./AnimatedExample'),
  require('./LayoutAnimationExample'),
  require('./AsyncStorageExample'),
  require('./BorderExample'),
  require('./LayoutExample'),
  require('./LinkingExample'),
  require('./TransformExample'),
  require('./XHRExample.macos'),
  require('./DragnDropExample.macos'),
  require('./MenuExample.macos'),
  require('./PanResponderExample'),
];

type Props = {
  openExample: Function,
};

export class UIExplorerList extends React.Component {
  props: Props;
  state: any;

  render() {
    return (
      <UIExplorerListBase
        components={Components}
        apis={APIS}
        searchText={Settings.get('searchText')}
        renderAdditionalView={this.renderAdditionalView.bind(this)}
        search={this.search.bind(this)}
        onPressRow={this.onPressRow.bind(this)}
      />
    );
  }

  renderAdditionalView(renderRow: Function, renderTextInput: Function) {
    return renderTextInput(styles.searchTextInput);
  }

  search(text: mixed) {
    Settings.set({ searchText: text });
  }

  onPressRow(example: any) {
    var Component = UIExplorerListBase.makeRenderable(example);
    this.props.openExample(Component);
  }

  // Register suitable examples for snapshot tests
  static registerComponents() {
    Components.concat(APIS).forEach((Example: any) => {
      if (Example.displayName) {
        var Snapshotter = React.createClass({
          render: function() {
            var Renderable = UIExplorerListBase.makeRenderable(Example);
            return (
              <SnapshotViewIOS>
                <Renderable />
              </SnapshotViewIOS>
            );
          },
        });
        AppRegistry.registerComponent(Example.displayName, () => Snapshotter);
      }
    });
  }
}

export type UIExplorerExample = any;

var styles = StyleSheet.create({
  searchTextInput: {
    height: 20,
  },
});
