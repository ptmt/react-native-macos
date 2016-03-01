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

var Platform = require('Platform');
var React = require('react-native-desktop');
var {
  StyleSheet,
  Text,
  View,
} = React;

var styles = StyleSheet.create({
  box: {
    backgroundColor: '#527FE4',
    borderColor: '#000033',
    borderWidth: 1,
  }
});

exports.title = 'Dran\'n\'Drop';
exports.description = 'Dragging APIs';

var DragExample = React.createClass({
  getInitialState() {
    return {
      dragOver: false,
      files: []
    }
  },
  render() {
    return (
      <View
        style={{backgroundColor: this.state.dragOver ? 'yellow' : '#527FE4', padding: 40, alignItems: 'center'}}
        draggedTypes={['NSFilenamesPboardType']}
        onDragEnter={() => this.setState({dragOver: true})}
        onDragLeave={() => this.setState({dragOver: false})}
        onDrop={(e) => this.setState({files: e.nativeEvent.files, dragOver: false})}>
        <Text style={{fontSize: 14, color: 'black'}}>
          {this.state.files.length > 0 ? this.state.files : 'Drag here a file'}
        </Text>

      </View>
    )
  }
})
exports.displayName = 'Dran\'n\'Drop';
exports.examples = [
  {
    title: 'Simple events',
    render: function() {
      return (
        <DragExample />
      );
    },
  }
];
