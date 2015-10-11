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

var React = require('react-native-desktop');

var {
  AppRegistry,
  StyleSheet,
  View,
  Text
} = React;

class UIExplorerApp extends React.Component {

  render() {
    return (
      <View style={styles.container}>
        <View style={{width: 200, padding: 20, backgroundColor: '#333'}}>
          <Text style={{color: 'white'}}>Components:</Text>
          <Text style={{color: 'white'}}>APIs</Text>
        </View>
      </View>
    );
  }

}

var styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#ddd',
    flexDirection: 'row'
  },
  itemWrapper: {
    backgroundColor: '#eaeaea',
  },
});

AppRegistry.registerComponent('UIExplorerApp', () => UIExplorerApp);

module.exports = UIExplorerApp;
