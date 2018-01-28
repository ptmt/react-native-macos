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

const ColorPropType = require('ColorPropType');
const Platform = require('Platform');
const React = require('React');
const PropTypes = require('prop-types');
const StyleSheet = require('StyleSheet');
const Text = require('Text');
const TouchableNativeFeedback = require('TouchableNativeFeedback');
const TouchableOpacity = require('TouchableOpacity');
const View = require('View');

const invariant = require('fbjs/lib/invariant');

const requireNativeComponent = require('requireNativeComponent');
const NativeModules = require('NativeModules');

/**
 * A basic button component that should render nicely on any platform. Supports
 * a minimal level of customization.
 *
 * <center><img src="img/buttonExample.png"></img></center>
 *
 * If this button doesn't look right for your app, you can build your own
 * button using [TouchableOpacity](docs/touchableopacity.html)
 * or [TouchableNativeFeedback](docs/touchablenativefeedback.html).
 * For inspiration, look at the [source code for this button component](https://github.com/facebook/react-native/blob/master/Libraries/Components/Button.js).
 * Or, take a look at the [wide variety of button components built by the community](https://js.coach/react-native?search=button).
 *
 * Example usage:
 *
 * ```
 * import { Button } from 'react-native';
 * ...
 *
 * <Button
 *   onPress={onPressLearnMore}
 *   title="Learn More"
 *   color="#841584"
 *   accessibilityLabel="Learn more about this purple button"
 * />
 * ```
 *
 */

class Button extends React.Component<{
  title: string,
  onPress: () => any,
  color?: ?string,
  accessibilityLabel?: ?string,
  disabled?: ?boolean,
  testID?: ?string,
  hasTVPreferredFocus?: ?boolean,
}> {
  static propTypes = {
    /**
     * Text to display inside the button
     */
    title: PropTypes.string,
    /**
     * Text to display for blindness accessibility features
     */
    accessibilityLabel: PropTypes.string,
    /**
     * Color of the text (iOS), or background color of the button (Android)
     */
    color: ColorPropType,
    /**
     * If true, disable all interactions for this component.
     */
    disabled: PropTypes.bool,
    /**
     * Handler to be called when the user taps the button
     */
    onPress: PropTypes.func,
    /**
     * Used to locate this view in end-to-end tests.
     */
    testID: PropTypes.string,
    /**
     * macOS Specific
     */
    type: PropTypes.oneOf([
      'momentaryLight',
      'push',
      'switch',
      'toggle',
      'radio',
      'onOff',
      'accelerator',
    ]),
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
    bezelStyle: PropTypes.oneOf([
      'rounded',
      'regularSquare',
      'thickSquare',
      'thickerSquare',
      'disclosure',
      'shadowlessSquare',
      'circular',
      'texturedSquare',
      'helpButton',
      'smallSquare',
      'texturedRounded',
      'roundRect',
      'recessed',
      'roundedDisclosure',
      'inline',
    ]),
    toolTip: PropTypes.string,
    allowsMixedState: PropTypes.bool,
    state: PropTypes.oneOfType([PropTypes.number, PropTypes.bool]),
    style: PropTypes.any,
  };

  render() {
    const {
      accessibilityLabel,
      color,
      onPress,
      title,
      hasTVPreferredFocus,
      disabled,
      testID,
    } = this.props;
    const buttonStyles = [styles.button];
    const textStyles = [styles.text];
    const Touchable = Platform.OS === 'android'
      ? TouchableNativeFeedback
      : TouchableOpacity;
    if (color && Platform.OS === 'ios') {
      textStyles.push({ color: color });
    } else if (color) {
      buttonStyles.push({ backgroundColor: color });
    }
    const accessibilityTraits = ['button'];
    if (disabled) {
      buttonStyles.push(styles.buttonDisabled);
      textStyles.push(styles.textDisabled);
      accessibilityTraits.push('disabled');
    }
    if (Platform.OS === 'ios' || Platform.OS === 'android') {
      invariant(
        typeof title === 'string',
        'The title prop of a Button must be a string'
      );
    }
    const formattedTitle = Platform.OS === 'android'
      ? title.toUpperCase()
      : title;
    const accessibilityTraits = ['button'];
    if (disabled) {
      accessibilityTraits.push('disabled');
    }
    if (Platform.OS === 'macos') {
      return (
        <RCTButton {...this.props} style={[styles.button, this.props.style]} />
      );
    }
    return (
      <Touchable
        accessibilityComponentType="button"
        accessibilityLabel={accessibilityLabel}
        accessibilityTraits={accessibilityTraits}
        hasTVPreferredFocus={hasTVPreferredFocus}
        testID={testID}
        disabled={disabled}
        onPress={onPress}>
        <View style={buttonStyles}>
          <Text style={textStyles} disabled={disabled}>{formattedTitle}</Text>
        </View>
      </Touchable>
    );
  }
}

// Material design blue from https://material.google.com/style/color.html#color-color-palette
let defaultBlue = '#2196F3';
if (Platform.OS === 'ios') {
  // Measured default tintColor from iOS 10
  defaultBlue = '#0C42FD';
}

const RCTButton = requireNativeComponent('RCTButton', Button, {
  nativeOnly: {},
});


const styles = StyleSheet.create({
  button: Platform.select({
    ios: {},
    android: {
      elevation: 4,
      // Material design blue from https://material.google.com/style/color.html#color-color-palette
      backgroundColor: '#2196F3',
      borderRadius: 2,
    },
    macos: {
      height: NativeModules.ButtonManager.ComponentHeight,
      width: NativeModules.ButtonManager.ComponentWidth,
    },
  }),
  text: Platform.select({
    ios: {
      // iOS blue from https://developer.apple.com/ios/human-interface-guidelines/visual-design/color/
      color: '#007AFF',
      textAlign: 'center',
      padding: 8,
      fontSize: 18,
    },
    android: {
      color: 'white',
      textAlign: 'center',
      padding: 8,
      fontWeight: '500',
    },
  }),
  buttonDisabled: Platform.select({
    ios: {},
    android: {
      elevation: 0,
      backgroundColor: '#dfdfdf',
    },
  }),
  textDisabled: Platform.select({
    ios: {
      color: '#cdcdcd',
    },
    android: {
      color: '#a1a1a1',
    },
  }),
});

module.exports = Button;
