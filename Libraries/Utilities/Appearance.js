/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 *
 * @providesModule Appearance
 * @flow
 */
'use strict';

const Appearance = require('NativeModules').Appearance;
const NativeEventEmitter = require('NativeEventEmitter');
const processColor = require('processColor')

const invariant = require('fbjs/lib/invariant');

invariant(Appearance, 'Appearance native module is not installed correctly');

type RGBColor = string | number;
export type AppearanceConfig = {
  currentAppearance: String,
  colors: {
    [name: String]: RGBColor
  }
}

class AppearanceManager extends NativeEventEmitter {

  constructor() {
    super(Appearance);
  }

  addEventListener(type: string, handler: Function) {
    return this.addListener(type, handler);
  }

  removeSubscription(subscription: any) {
    if (subscription.emitter !== this) {
      subscription.emitter.removeSubscription(subscription);
    } else {
      super.removeSubscription(subscription);
    }
  }

  static get initial(): AppearanceConfig { 
    return {
      colors: Appearance.colors,
      currentAppearance: Appearance.currentAppearance
    };
  }

  static highlightWithLevel(color: RGBColor, level: Number): Promise<RGBColor> {
    return Appearance.highlightWithLevel(processColor(color), level)
  }

  static shadowWithLevel(color: RGBColor, level: Number): Promise<RGBColor> {
    return Appearance.shadowWithLevel(processColor(color), level)
  }
}

module.exports = AppearanceManager;
