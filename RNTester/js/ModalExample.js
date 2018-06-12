/**
 * Copyright (c) 2013-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 *
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

var React = require('react');
var ReactNative = require('react-native');
var { Modal, StyleSheet, Switch, Text, Button, View } = ReactNative;

exports.displayName = (undefined: ?string);
exports.framework = 'React';
exports.title = '<Modal>';
exports.description = 'Component for presenting modal views.';

class ModalExample extends React.Component {
  state = {
    presentationType: 'window',
    modalVisible: false,
    transparent: false,
  };

  _setModalVisible = visible => {
    this.setState({ modalVisible: visible });
    console.log('hide modal');
  };

  _setPresentationType(type) {
    this.setState({ presentationType: type });
  }

  _toggleTransparent = () => {
    this.setState({ transparent: !this.state.transparent });
  };

  render() {
    var modalBackgroundStyle = {
      backgroundColor: this.state.transparent
        ? 'rgba(0, 0, 0, 0.5)'
        : '#f5fcff',
    };
    var innerContainerTransparentStyle = this.state.transparent
      ? { backgroundColor: '#fff', padding: 20 }
      : null;
    var activeButtonStyle = {
      backgroundColor: '#ddd',
    };

    return (
      <View>
        <Modal
          width={300}
          presentationType={this.state.presentationType}
          transparent={this.state.transparent}
          visible={this.state.modalVisible}
          onRequestClose={() => {
            this._setModalVisible(false);
          }}>
          <View style={[styles.container, modalBackgroundStyle]}>
            <View
              style={[styles.innerContainer, innerContainerTransparentStyle]}>
              <Text>
                This modal was presented with type:
                {' '}
                {this.state.presentationType}
                .
              </Text>
              <Button
                onPress={this._setModalVisible.bind(this, false)}
                style={styles.modalButton}
                title="Close"
              />
            </View>
          </View>
        </Modal>
        <View style={styles.row}>
          <Text style={styles.rowTitle}>Presentation Type</Text>
          <Button
            onClick={this._setPresentationType.bind(this, 'window')}
            state={this.state.presentationType === 'window'}
            style={{ width: 200 }}
            type="radio"
            title="window"
          />
          <Button
            onClick={this._setPresentationType.bind(this, 'sheet')}
            state={this.state.presentationType === 'sheet'}
            style={{ width: 200 }}
            type="radio"
            title="sheet"
          />
          <Button
            onClick={this._setPresentationType.bind(this, 'popover')}
            state={this.state.presentationType === 'popover'}
            style={{ width: 200 }}
            type="radio"
            title="popover"
          />
        </View>

        <View style={styles.row}>
          <Text style={styles.rowTitle}>Transparent</Text>
          <Switch
            value={this.state.transparent}
            onValueChange={this._toggleTransparent}
          />
        </View>

        <Button
          bezelStyle={'rounded'}
          style={{ width: 100, fontSize: 18, height: 40 }}
          onClick={this._setModalVisible.bind(this, true)}
          title="Present"
        />

      </View>
    );
  }
}

exports.examples = [
  {
    title: 'Modal Presentation',
    description: 'Modals can be presented with or without animation',
    render: () => <ModalExample />,
  },
];

var styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    padding: 20,
  },
  innerContainer: {
    borderRadius: 10,
    alignItems: 'center',
  },
  row: {
    alignItems: 'center',
    flex: 1,
    flexDirection: 'row',
    marginBottom: 20,
  },
  rowTitle: {
    flex: 1,
    fontWeight: 'bold',
  },
  button: {
    borderRadius: 5,
    margin: 10,
    backgroundColor: 'lightblue',
    flex: 1,
    height: 44,
    alignSelf: 'stretch',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  buttonText: {
    fontSize: 18,
    margin: 5,
    textAlign: 'center',
  },
  modalButton: {
    marginTop: 10,
  },
});
