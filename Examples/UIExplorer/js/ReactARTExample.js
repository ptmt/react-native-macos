/* @Flow */

import React from 'react';
import ReactNative from 'react-native-macos';

const {
  View,
  PanResponder,
} = ReactNative;

var ReactART = require('ReactNativeART');

const {
  Shape,
  Group,
  Surface,
  Transform
} = ReactART;

class ErasingShape extends React.Component {

  constructor() {
    super();

    this.state = {
      svgPath: [],
      value: 0,
      letter: 'M',
      strokeWidth: 8
    };
  }

  componentWillMount() {
    this._panResponder = PanResponder.create({
      // Ask to be the responder:
      onStartShouldSetPanResponder: (evt, gestureState) => true,
      onStartShouldSetPanResponderCapture: (evt, gestureState) => true,
      onMoveShouldSetPanResponder: (evt, gestureState) => true,
      onMoveShouldSetPanResponderCapture: (evt, gestureState) => true,

      onPanResponderGrant: (evt, gestureState) => {
        // console.log('onPanResponderGrant', gestureState, this.state.fx, this.state.fy)
        //var letter = this.state.svgPath.length > 0 ? 'L' : 'M';
        this.state.svgPath.push(
            this.state.letter + Math.round(gestureState.x0 - this.state.px)
            + ',' +  Math.round(gestureState.y0 - this.state.py));
        this.setState({svgPath: this.state.svgPath, letter: 'L'});
        // gestureState.{x,y}0 will be set to zero now
      },
      onPanResponderMove: (evt, gestureState) => {
        // The most recent move distance is gestureState.move{X,Y}
        this.state.svgPath.push(this.state.letter +
          Math.round(gestureState.moveX - this.state.px) + ',' +
          Math.round(gestureState.moveY - this.state.py));
        this.setState({svgPath: this.state.svgPath});
      },
      onPanResponderTerminationRequest: (evt, gestureState) => true,
      onPanResponderRelease: (evt, gestureState) => {
        this.setState({letter: 'M'});
        // The user has released all touches while this view is the
        // responder. This typically means a gesture has succeeded
      },
      onPanResponderTerminate: (evt, gestureState) => {
        // Another component has become the responder, so this gesture
        // should be cancelled
      },
      onShouldBlockNativeResponder: (evt, gestureState) => {
        // Returns whether this component should block native components from becoming the JS
        // responder. Returns true by default. Is currently only supported on android.
        return true;
      },
    });
  }

  render() {
    return (
      <View {...this._panResponder.panHandlers}
        ref={ref => { this.ref = ref; }}
        onLayout={(e) => this.ref.measure( (fx, fy, w, h, px, py) => {
          this.setState({ px, py });
        })}
        style={[this.props.style, {flex: 1, height: 200, width: 500, backgroundColor: '#eee'}]}>
        <Surface width={500} height={200}>
          <Shape d={this.state.svgPath.join('')}
                 stroke="#88C76D"
                 strokeWidth={this.state.strokeWidth} />
        </Surface>
      </View>
    );
  }
}

var MOUSE_UP_DRAG = 0.978;
var BASE_VEL = 0.15;
/**
 * An animated SVG component.
 */
var VectorWidget = React.createClass({
  /**
   * Initialize state members.
   */
  getInitialState: function() {
    return {degrees: 0, velocity: 0, drag: MOUSE_UP_DRAG};
  },
  /**
   * When the component is mounted into the document - this is similar to a
   * constructor, but invoked when the instance is actually mounted into the
   * document. Here's, we'll just set up an animation loop that invokes our
   * method. Binding of `this.onTick` is not needed because all React methods
   * are automatically bound before being mounted.
   */
  componentDidMount: function() {
    this._interval = window.setInterval(this.onTick, 20);
  },
  componentWillUnmount: function() {
    window.clearInterval(this._interval);
  },
  onTick: function() {
    var nextDegrees = this.state.degrees + BASE_VEL + this.state.velocity;
    var nextVelocity = this.state.velocity * this.state.drag;
    this.setState({degrees: nextDegrees, velocity: nextVelocity});
  },
  /**
   * This is the "main" method for any component. The React API allows you to
   * describe the structure of your UI component at *any* point in time.
   */
  render: function() {
    return (
      <Surface
        width={700}
        height={400}
      >
        {this.renderGraphic(this.state.degrees)}
      </Surface>
    );
  },
  renderGraphic: function(rotation) {
    return (
      <Group>
        <Group x={110} y={35}>
          <Shape fill="rgba(0,0,0,0.1)" d={BORDER_PATH} />
          <Shape fill="#7BC7BA" d={BG_PATH} />
          <Shape fill="#DCDCDC" d={BAR_PATH} />
          <Shape fill="#D97B76" d={RED_DOT_PATH} />
          <Shape fill="#DBBB79" d={YELLOW_DOT_PATH} />
          <Shape fill="#A6BD8A" d={GREEN_DOT_PATH} />
          <Group x={55} y={29}>
            <Group rotation={rotation} originX={84} originY={89}>
              <Shape fill="#FFFFFF" d={CENTER_DOT_PATH} />
              <Group>
                <Shape d={RING_ONE_PATH} stroke="#FFFFFF" strokeWidth={8} />
                <Shape d={RING_TWO_PATH} transform={RING_TWO_ROTATE} stroke="#FFFFFF" strokeWidth={8} />
                <Shape d={RING_THREE_PATH} transform={RING_THREE_ROTATE} stroke="#FFFFFF" strokeWidth={8} />
              </Group>
            </Group>
          </Group>
        </Group>
      </Group>
    );
  }
});
var BORDER_PATH = "M3.00191459,4 C1.34400294,4 0,5.34785514 0,7.00550479 L0,220.994495 C0,222.65439 1.34239483,224 3.00191459,224 L276.998085,224 C278.655997,224 280,222.652145 280,220.994495 L280,7.00550479 C280,5.34561033 278.657605,4 276.998085,4 L3.00191459,4 Z M3.00191459,4";
var BG_PATH = "M3.00191459,1 C1.34400294,1 0,2.34785514 0,4.00550479 L0,217.994495 C0,219.65439 1.34239483,221 3.00191459,221 L276.998085,221 C278.655997,221 280,219.652145 280,217.994495 L280,4.00550479 C280,2.34561033 278.657605,1 276.998085,1 L3.00191459,1 Z M3.00191459,1";
var BAR_PATH = "M3.00191459,0 C1.34400294,0 0,1.34559019 0,3.00878799 L0,21 C0,21 0,21 0,21 L280,21 C280,21 280,21 280,21 L280,3.00878799 C280,1.34708027 278.657605,0 276.998085,0 L3.00191459,0 Z M3.00191459,0";
var RED_DOT_PATH = "M12.5,17 C16.0898511,17 19,14.0898511 19,10.5 C19,6.91014895 16.0898511,4 12.5,4 C8.91014895,4 6,6.91014895 6,10.5 C6,14.0898511 8.91014895,17 12.5,17 Z M12.5,17";
var YELLOW_DOT_PATH = "M31.5,17 C35.0898511,17 38,14.0898511 38,10.5 C38,6.91014895 35.0898511,4 31.5,4 C27.9101489,4 25,6.91014895 25,10.5 C25,14.0898511 27.9101489,17 31.5,17 Z M31.5,17";
var GREEN_DOT_PATH = "M50.5,17 C54.0898511,17 57,14.0898511 57,10.5 C57,6.91014895 54.0898511,4 50.5,4 C46.9101489,4 44,6.91014895 44,10.5 C44,14.0898511 46.9101489,17 50.5,17 Z M50.5,17";
var CENTER_DOT_PATH = "M84,105 C92.8365564,105 100,97.8365564 100,89 C100,80.1634436 92.8365564,73 84,73 C75.1634436,73 68,80.1634436 68,89 C68,97.8365564 75.1634436,105 84,105 Z M84,105";
var RING_ONE_PATH = "M84,121 C130.391921,121 168,106.673113 168,89 C168,71.3268871 130.391921,57 84,57 C37.6080787,57 0,71.3268871 0,89 C0,106.673113 37.6080787,121 84,121 Z M84,121";
var RING_TWO_PATH = "M84,121 C130.391921,121 168,106.673113 168,89 C168,71.3268871 130.391921,57 84,57 C37.6080787,57 0,71.3268871 0,89 C0,106.673113 37.6080787,121 84,121 Z M84,121";
var RING_THREE_PATH = "M84,121 C130.391921,121 168,106.673113 168,89 C168,71.3268871 130.391921,57 84,57 C37.6080787,57 0,71.3268871 0,89 C0,106.673113 37.6080787,121 84,121 Z M84,121";
var RING_TWO_ROTATE = new Transform().translate(84.000000, 89.000000).rotate(-240.000000).translate(-84.000000, -89.000000);
var RING_THREE_ROTATE = new Transform().translate(84.000000, 89.000000).rotate(-300.000000).translate(-84.000000, -89.000000);


exports.title = 'ReactART';
exports.description = 'React Native bridge to ART drawing library';
exports.displayName = 'ReactART';
exports.examples = [ {
  title: 'Simple vector editor',
  render: function () { return <ErasingShape />; }
}, {
  title: 'Vector Widget',
  render: function() {return <VectorWidget />; }
}];
