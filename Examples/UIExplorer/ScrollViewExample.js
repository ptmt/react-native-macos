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
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
  Image,
  Text
} = React;

exports.displayName = (undefined: ?string);
exports.title = '<ScrollView>';
exports.description = 'Component that enables scrolling through child components';
exports.examples = [
{
  title: '<ScrollView>',
  description: 'To make content scrollable, wrap it within a <ScrollView> component',
  render: function() {
    var _scrollView: ScrollView;
    return (
      <View>
        <ScrollView
          ref={(scrollView) => { _scrollView = scrollView; }}
          automaticallyAdjustContentInsets={false}
          onScroll={() => { console.log('onScroll!'); }}
          scrollEventThrottle={200}
          style={styles.scrollView}>
          {THUMBS.map(createThumbRow)}
        </ScrollView>
        <TouchableOpacity
          style={styles.button}
          onPress={() => { _scrollView.scrollTo({y: 0}); }}>
          <Text>Scroll to top</Text>
        </TouchableOpacity>
      </View>
    );
  }
}, {
  title: '<ScrollView> (horizontal = true)',
  description: 'You can display <ScrollView>\'s child components horizontally rather than vertically',
  render: function() {
    var _scrollView: ScrollView;
    return (
      <View>
        <ScrollView
          ref={(scrollView) => { _scrollView = scrollView; }}
          automaticallyAdjustContentInsets={false}
          horizontal={true}
          style={[styles.scrollView, styles.horizontalScrollView]}>
          {THUMBS.map(createThumbRow)}
        </ScrollView>
        <TouchableOpacity
          style={styles.button}
          onPress={() => { _scrollView.scrollTo({x: 0}); }}>
          <Text>Scroll to start</Text>
        </TouchableOpacity>
      </View>
    );
  }
},
, {
  title: 'Inverted <ScrollView>',
  description: 'Auto scroll content to bottom',
  render: function() {
    const texts = TEXTS.map((t, i)=> <Text key={i}>{i} - {t}</Text>);
    return (
      <ScrollView
        automaticallyAdjustContentInsets={false}
        style={styles.scrollView}
        autoScrollToBottom={true}>
        {texts}
      </ScrollView>
    );
  }
}];

var Thumb = React.createClass({
  shouldComponentUpdate: function(nextProps, nextState) {
    return false;
  },
  render: function() {
    return (
      <View style={styles.button}>
        <Image style={styles.img} source={{uri:this.props.uri}} />
      </View>
    );
  }
});

var THUMBS = new Array(20)
  .join()
  .split(',')
  .map(x => 'http://facebook.github.io/react/img/logo_og.png');

var TEXTS = new Array(100)
  .join()
  .split(',')
  .map(x => Math.random().toString(36).replace(/[^a-z]+/g, ''));

var createThumbRow = (uri, i) => <Thumb key={i} uri={uri} />;

var styles = StyleSheet.create({
  scrollView: {
    //backgroundColor: '#6A85B1',
    height: 300,
  },
  horizontalScrollView: {
    height: 120,
  },
  containerPage: {
    height: 50,
    width: 50,
    backgroundColor: '#527FE4',
    padding: 5,
  },
  inverted: {
    transform: [{scaleY: -1}]
  },
  text: {
    fontSize: 20,
    color: '#888888',
    left: 80,
    top: 20,
    height: 40,
  },
  button: {
    margin: 7,
    padding: 5,
    alignItems: 'center',
    backgroundColor: '#eaeaea',
    borderRadius: 3,
  },
  buttonContents: {
    flexDirection: 'row',
    width: 64,
    height: 64,
  },
  img: {
    width: 64,
    height: 64,
  }
});
