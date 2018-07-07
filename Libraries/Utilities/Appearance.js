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

class AppearanceManager extends NativeEventEmitter {

  constructor() {
    super(Appearance);
  }

  /**
   * Add a handler to Linking changes by listening to the `url` event type
   * and providing the handler
   */
  addEventListener(type: string, handler: Function) {
    this.addListener(type, handler);
  }

  /**
   * Remove a handler by passing the `url` event type and the handler
   */
  removeEventListener(type: string, handler: Function ) {
    this.removeListener(type, handler);
  }

  static get initial() { 
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
