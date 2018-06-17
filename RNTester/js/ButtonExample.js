/*
  @flow
*/
'use strict';

const React = require('React');
const ReactNative = require('react-native');

const { Button, View } = ReactNative;

const BEZEL_STYLES = [
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
];

const AllStyles = ({ type }) => {
  return (
    <View style={{ flexDirection: 'row', flexWrap: 'wrap' }}>
      {BEZEL_STYLES.map((style, i) => (
        <Button
          key={i}
          style={{ width: 150, margin: 15 }}
          type={type}
          title={style.toString()}
          toolTip={`tooltip: for style=${style} with type=${type}`}
          bezelStyle={style}
          onPress={() => alert(`clicked on: style=${style} type=${type}`)}
        />
      ))}
    </View>
  );
};

exports.title = '<Button>';
exports.description = 'macOS native buttons with different styles';
exports.examples = [
  {
    title: 'Default',
    description: 'Default button',
    render() {
      return (
        <Button
          title="Button"
          onPress={() => alert(`clicked on default button`)}
        />
      );
    },
  },
  {
    title: 'Momentary Light',
    description: 'This type of button is best for simply triggering actions because it doesn’t show its state; it always displays its normal image or title.',
    render() {
      return <AllStyles type={'momentaryLight'} />;
    },
  },
  {
    title: 'Push button',
    description: 'When the button is clicked (on state), it appears illuminated. If the button has borders, it may also appear recessed. A second click returns it to its normal (off) state.',
    render() {
      return <AllStyles type={'push'} />;
    },
  },
  {
    title: 'Toggle',
    description: 'After the first click, the button displays its alternate image or title (on state); a second click returns the button to its normal (off) state.',
    render() {
      return (
        <Button
          type={'toggle'}
          style={{ width: 200 }}
          title={'button title'}
          alternateTitle={'Alternate title'}
        />
      );
    },
  },
  {
    title: 'Switch',
    description: 'This style is a variant of NSToggleButton that has no border and is typically used to represent a checkbox.',
    render() {
      return (
        <View>
          <Button
            type={'switch'}
            style={{ width: 250 }}
            title={'Single Checkbox'}
            state={0}
          />
          <Button
            type={'switch'}
            style={{ width: 250 }}
            title={'Single Checkbox'}
            state={1}
          />
          <Button
            type={'switch'}
            style={{ width: 250 }}
            title={'Single Checkbox'}
            allowsMixedState={true}
            state={-1}
          />
        </View>
      );
    },
  },
  {
    title: 'Radio',
    description: 'This style is similar to NSSwitchButton, but it is used to constrain a selection to a single element from several elements.',
    render() {
      return (
        <View>
          <Button
            type={'radio'}
            style={{ width: 200 }}
            title={'Single Radio'}
            state={0}
          />
          <Button
            type={'radio'}
            style={{ width: 200 }}
            title={'Single Radio'}
            state={1}
          />
          <Button
            type={'radio'}
            style={{ width: 200 }}
            title={'Single Radio'}
            allowsMixedState={true}
            state={-1}
          />
        </View>
      );
    },
  },
  {
    title: 'onOff button',
    description: 'The first click highlights the button; a second click returns it to the normal (unhighlighted) state.',
    render() {
      return <AllStyles type={'onOff'} />;
    },
  },
  {
    title: 'Image Button',
    description: 'four different styles (circular, disclosure, roundedDisclosure, helpButton)',
    render() {
      return (
        <View style={{ flexDirection: 'row', flexWrap: 'wrap' }}>
          <Button
            bezelStyle={'circular'}
            image={require('./uie_thumb_normal.png')}
            style={styles.icon}
          />
          <Button
            bezelStyle={'disclosure'}
            image={require('./uie_thumb_normal.png')}
            style={styles.icon}
          />
          <Button
            bezelStyle={'roundedDisclosure'}
            image={require('./uie_thumb_normal.png')}
            style={styles.icon}
          />
          <Button bezelStyle={'helpButton'} title={''} style={styles.icon} />
        </View>
      );
    },
  },
];

const styles = {
  icon: {
    width: 60,
    height: 60,
  },
};
