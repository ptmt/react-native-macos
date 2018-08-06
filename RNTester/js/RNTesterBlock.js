/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 *
 * @providesModule RNTesterBlock
 * @flow
 */
'use strict';

var React = require('react');
var PropTypes = require('prop-types');
var ReactNative = require('react-native');
var {
  StyleSheet,
  Text,
  View,
} = ReactNative;

import { AppearanceConsumer } from './AppearanceContext'


class RNTesterBlock extends React.Component<{
  title?: string,
  description?: string,
}, $FlowFixMeState> {
  static propTypes = {
    title: PropTypes.string,
    description: PropTypes.string,
  };

  state = {description: (null: ?string)};

  backgroundColor(appearance: any) {
    return appearance.currentAppearance.indexOf("Dark") > -1 ? "#292A2F" : "white"
  }

  borderColor(appearance: any, utils) {
    const isDark = appearance.currentAppearance.indexOf("Dark") > -1;
    return isDark ? utils.tint(0.86, this.backgroundColor(appearance)) : utils.shade(0.85, this.backgroundColor(appearance))
  }

  render() {
    var description;
    if (this.props.description) {
      description =
        <Text style={styles.descriptionText}>
          {this.props.description}
        </Text>;
    }

    return (
      <AppearanceConsumer resolveColors={(a, utils) => ({ borderColor: this.borderColor(a, utils) })}>
        {(appearance, { borderColor }) => (
          <View style={[styles.container, { borderColor, backgroundColor: this.backgroundColor(appearance)}]}>
            <View style={[styles.titleContainer, {backgroundColor: appearance.colors.textBackgroundColor, borderBottomColor: borderColor }]}>
              <Text style={[styles.titleText, { color: appearance.colors.textColor } ]}>
                {this.props.title}
              </Text>
              {description}
            </View>
            <View style={styles.children}>
              {
                // $FlowFixMe found when converting React.createClass to ES6
                this.props.children}
            </View>
          </View>
        )}
      </AppearanceConsumer>
    );
  }
}

var styles = StyleSheet.create({
  container: {
    borderRadius: 3,
    borderWidth: 0.5,
    margin: 10,
    marginVertical: 5,
    overflow: 'hidden',
  },
  titleContainer: {
    borderBottomWidth: 0.5,
    borderTopLeftRadius: 3,
    borderTopRightRadius: 2.5,
    
    paddingHorizontal: 10,
    paddingVertical: 5,
  },
  titleText: {
    fontSize: 14,
    fontWeight: '500',
  },
  descriptionText: {
    fontSize: 14,
  },
  disclosure: {
    position: 'absolute',
    top: 0,
    right: 0,
    padding: 10,
  },
  disclosureIcon: {
    width: 12,
    height: 8,
  },
  children: {
    margin: 10,
  }
});

module.exports = RNTesterBlock;
