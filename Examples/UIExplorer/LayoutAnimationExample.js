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
  Animated,
  LayoutAnimation,
  Easing,
  StyleSheet,
  Text,
  View,
} = React;
var UIExplorerButton = require('./UIExplorerButton');

var animations = {
  linear: {
    duration: 300,
    create: {
      type: LayoutAnimation.Types.linear,
      property: LayoutAnimation.Properties.opacity,
    },
    update: {
      type: LayoutAnimation.Types.linear,
      property: LayoutAnimation.Properties.opacity,
    },
  },
  easeInEaseOut: {
    duration: 300,
    create: {
      type: LayoutAnimation.Types.easeInEaseOut,
      property: LayoutAnimation.Properties.scaleXY,
    },
    update: {
      delay: 100,
      type: LayoutAnimation.Types.easeInEaseOut,
    },
  },
};

exports.framework = 'React';
exports.title = 'LayoutAnimation - Examples';
exports.description = 'LayoutAnimation allows you to animate all views in the next render/layout cycle';

exports.examples = [
  {
    title: 'LayoutAnimation',
    render: function() {
      class LayoutAnimationExample extends React.Component {
        constructor(props) {
          super(props);
          this.state = {
            show: true,
          };
        }
        render() {
          return (
            <View>
              <UIExplorerButton onPress={() => {
                  LayoutAnimation.configureNext(animations.easeInEaseOut);
                  this.setState((state) => (
                    {show: !this.state.show}
                  ));
                }}>
                Press to animate - linear
              </UIExplorerButton>
              <UIExplorerButton onPress={() => {
                  LayoutAnimation.configureNext(animations.easeInEaseOut);
                  this.setState((state) => (
                    {show: !this.state.show}
                  ));
                }}>
                Press to animate - easeInEaseOut
              </UIExplorerButton>
              {this.state.show && <View style={styles.content}>
                <Text>LayoutAnimation</Text>
              </View>}
              <View style={styles.content}>
                <Text>LayoutAnimation</Text>
              </View>
            </View>
          );
        }
      }
      return <LayoutAnimationExample />;
    },
  },
];


var styles = StyleSheet.create({
  content: {
    backgroundColor: 'deepskyblue',
    borderWidth: 1,
    borderColor: 'dodgerblue',
    padding: 20,
    margin: 20,
    borderRadius: 10,
    alignItems: 'center',
  },
});
