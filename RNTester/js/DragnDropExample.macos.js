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

var React = require('React');
var ReactNative = require('react-native');
var {
  Text,
  View,
} = ReactNative;

exports.title = 'Dran\'n\'Drop';
exports.description = 'Dragging APIs';

class DragExample extends React.Component {
  state = {
    dragOver: false,
    mouseOver: false,
    files: []
  };

  render() {
    return (
      <View
        style={{
          backgroundColor: this.state.dragOver ?
            'yellow' :
            this.state.mouseOver ? 'orange' : 'white',
          padding: 40, alignItems: 'center'}}
        draggedTypes={['NSFilenamesPboardType']}
        onMouseOver={() => this.setState({mouseOver: true})}
        onMouseOut={() => this.setState({mouseOver: false})}
        onDragEnter={() => this.setState({dragOver: true})}
        onDragLeave={() => this.setState({dragOver: false})}
        onDrop={(e) => this.setState({files: e.nativeEvent.files, dragOver: false})}>
        <Text style={{fontSize: 14, color: 'black'}}>
          {this.state.files.length > 0 ? this.state.files : 'Drag here a file'}
        </Text>

      </View>
    );
  }
}

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
