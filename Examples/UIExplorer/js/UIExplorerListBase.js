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
var { StyleSheet, Text, TouchableOpacity, ScrollView, View } = ReactNative;
var createExamplePage = require('./createExamplePage');
var RCTDeviceEventEmitter = require('RCTDeviceEventEmitter');

// var ds = new ListView.DataSource({
//   rowHasChanged: (r1, r2) => r1 !== r2,
//   sectionHeaderHasChanged: (h1, h2) => h1 !== h2,
// });

class ListView extends React.Component {
  render() {
    var componentRows = this.props.dataSource.components.map((c, i) =>
      this.props.renderRow(c, i)
    );
    var apiRows = this.props.dataSource.apis.map((c, i) =>
      this.props.renderRow(c, i)
    );
    return (
      <ScrollView showsVerticalScrollIndicator={true}>
        {this.props.renderSectionHeader(null, 'Components')}
        {componentRows}
        {this.props.renderSectionHeader(null, 'APIs')}
        {apiRows}
      </ScrollView>
    );
  }
}

class UIExplorerListBase extends React.Component {
  state: any;
  constructor(props: any) {
    super(props);
    this.state = {
      // dataSource: ds.cloneWithRowsAndSections({
      //   components: [],
      //   apis: [],
      // }),
      dataSource: {
        components: [],
        apis: [],
      },
      searchText: this.props.searchText || '',
    };
  }

  componentDidMount(): void {
    RCTDeviceEventEmitter.addListener('onSearchExample', e =>
      this.search(e.query)
    );
    this.search(this.state.searchText);
  }

  render() {
    return (
      <View style={styles.listContainer}>

        <ListView
          style={styles.list}
          dataSource={this.state.dataSource}
          renderRow={this.renderRow.bind(this)}
          renderSectionHeader={this._renderSectionHeader}
          keyboardShouldPersistTaps={true}
          automaticallyAdjustContentInsets={false}
          keyboardDismissMode="on-drag"
        />
      </View>
    );
  }

  _renderSectionHeader(data: any, section: string) {
    return (
      <Text style={styles.sectionHeader}>
        {section}
      </Text>
    );
  }

  renderRow(example: any, i: number) {
    var selected = this.state.selected === example.title
      ? styles.selectedRow
      : {};
    return (
      <TouchableOpacity
        activeOpacity={0.8}
        onPress={() => this.onPressRow(example)}
        key={i}
        onClick={() => console.log('onClick')}
        style={[styles.row, selected]}>

        <Text style={styles.rowTitleText}>
          {example.title}
        </Text>
        <Text style={styles.rowDetailText}>
          {example.description}
        </Text>
      </TouchableOpacity>
    );
  }

  search(text: mixed): void {
    this.props.search && this.props.search(text);

    var regex = new RegExp(String(text), 'i');
    var filter = component => regex.test(component.title);

    this.setState({
      dataSource: {
        components: this.props.components.filter(filter),
        apis: this.props.apis.filter(filter),
      },
      searchText: text,
    });
  }

  onPressRow(example: any): void {
    this.setState({ selected: example.title });
    this.props.onPressRow && this.props.onPressRow(example);
  }

  static makeRenderable(example: any): ReactClass<any> {
    return example.examples ? createExamplePage(null, example) : example;
  }
}

var styles = StyleSheet.create({
  listContainer: {
    flex: 1,
  },
  list: {},
  sectionHeader: {
    paddingHorizontal: 7,
    paddingTop: 7,
    fontWeight: '600',
    fontSize: 11,
    color: '#777',
    letterSpacing: -0.2,
  },
  group: {},
  row: {
    justifyContent: 'center',
    paddingHorizontal: 15,
    paddingVertical: 8,
  },
  separator: {
    height: StyleSheet.hairlineWidth,
    backgroundColor: '#bbbbbb',
    marginLeft: 15,
  },
  rowTitleText: {
    fontSize: 13,
    fontWeight: '400',
  },
  rowDetailText: {
    fontSize: 10,
    color: '#888',
  },
  selectedRow: {
    backgroundColor: '#ddd',
  },
  hoveredRow: {
    backgroundColor: '#ddd',
  },
});

module.exports = UIExplorerListBase;
