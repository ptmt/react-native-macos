/* @flow */
import React from 'react';
import { Appearance } from 'react-native';

import * as colorUtils from 'polished'

// TODO: after upgrading to React 16.3+ move to React Context APIs
// export const AppearanceContext = React.createContext(
//   Appearance.initial
// );

// export const AppearanceContextConsumer = AppearanceContext.Consumer;
const AppearanceManager = new Appearance();


export class AppearanceConsumer extends React.Component<any, Appearance.AppearanceConfig> {
  listener: any;
  constructor(props: any) {
    super(props);
    this.state = {
      ...Appearance.initial,
      resolvedColors: props.resolveColors ? props.resolveColors(Appearance.initial, colorUtils) : {},
    }
  }
  componentDidMount() {
    this.listener = AppearanceManager.addEventListener("onAppearanceChange", async e => {
      this.setState(e);
      if (this.props.resolveColors) {
        const resolvedColors = this.props.resolveColors(e, colorUtils);
        this.setState({ resolvedColors })
      }
    }); 
  }
  componentWillUnmount() {
    AppearanceManager.removeSubscription(this.listener);
  }
  render() {
    return this.props.children(this.state, this.state.resolvedColors);
  }
}
