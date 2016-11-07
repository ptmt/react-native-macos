/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 *
 * @providesModule Button
 * @flow
 */
'use strict';

const NativeMethodsMixin = require('react/lib/NativeMethodsMixin');
const PropTypes = require('react/lib/ReactPropTypes');
const NativeModules = require('NativeModules');
const React = require('React');
const StyleSheet = require('StyleSheet');
const View = require('View');

var requireNativeComponent = require('requireNativeComponent');

type DefaultProps = {
  type: 'momentaryLight' | 'push' | 'switch' | 'toggle' | 'radio' | 'onOff' | 'accelerator';
};

const Button = React.createClass({
  mixins: [NativeMethodsMixin],

  propTypes: {
    ...View.propTypes,
    /**
     * Button's styles
     */
    type: PropTypes.oneOf([
      'momentaryLight',
      'push',
      'switch',
      'toggle',
      'radio',
      'onOff',
      'accelerator'
    ]),
    title: PropTypes.string,
    /*
     * https://developer.apple.com/library/mac/documentation/UserExperience/Conceptual/OSXHIGuidelines/SystemProvided.html
     */
    systemImage: PropTypes.string,
    alternateTitle: PropTypes.string,
    image: PropTypes.oneOfType([
      PropTypes.shape({
        uri: PropTypes.string,
      }),
      // Opaque type returned by require('./image.jpg')
      PropTypes.number,
    ]),
    alternateImage: PropTypes.oneOfType([
      PropTypes.shape({
        uri: PropTypes.string,
      }),
      // Opaque type returned by require('./image.jpg')
      PropTypes.number,
    ]),
    bezelStyle: PropTypes.oneOf(["rounded", "regularSquare", "thickSquare", "thickerSquare", "disclosure",
      "shadowlessSquare", "circular", "texturedSquare", "helpButton", "smallSquare", "texturedRounded",
      "roundRect", "recessed", "roundedDisclosure", "inline"]),
    toolTip: PropTypes.string,
    /**
     * Invoked on mount and layout changes with
     *
     *   {nativeEvent: { layout: {x, y, width, height}}}.
     */
    onLayout: PropTypes.func,
    /**
     * Invoked on mouse click
     *
     *   {nativeEvent: { state }}.
     */
    onClick: PropTypes.func,
    allowsMixedState: PropTypes.bool,
    state: PropTypes.oneOfType([PropTypes.number, PropTypes.bool]),
  },

  getDefaultProps: function(): DefaultProps {
    return {
      type: 'momentaryLight'
    };
  },

  render: function() {
    const { props } = this;
    return (
      <RCTButton {...props}
        style={[styles.defaultButton, props.style]} />
    );
  }
});

var styles = StyleSheet.create({
  defaultButton: {
    height: NativeModules.ButtonManager.ComponentHeight,
    width: NativeModules.ButtonManager.ComponentWidth
  },
});

var RCTButton = requireNativeComponent(
  'RCTButton',
  Button,
  {nativeOnly: {}},
);

module.exports = Button;
