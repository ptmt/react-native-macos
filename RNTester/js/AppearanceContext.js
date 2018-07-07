/* @flow */
import React from 'react';
import { Appearance } from 'react-native';

// TODO: after upgrading to React 16.3+ move to React Context APIs
// export const AppearanceContext = React.createContext(
//   Appearance.initial
// );

// export const AppearanceContextConsumer = AppearanceContext.Consumer;
const AppearanceManager = new Appearance();

export class AppearanceConsumer extends React.Component<any> {
  state: Appearance.AppearanceConfig = Appearance.initial
  listener: any;
  componentDidMount() {
    this.listener = AppearanceManager.addEventListener("onAppearanceChange", e => this.setState(e));
    console.log('added listener', this.listener)
  }
  componentWillUnmount() {
    console.log('removing', this.listener)
    AppearanceManager.removeSubscription(this.listener);
  }
  render() {
    return this.props.children(this.state);
  }
}
