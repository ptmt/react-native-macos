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

const invariant = require('fbjs/lib/invariant');

invariant(Appearance, 'Appearance native module is not installed correctly');

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

  static get colors() { return Appearance.colors }
  static get currentAppearance() { return Appearance.currentAppearance }
  static get isDark() { return Appearance.currentAppearance.toLowerCase().indexOf("dark") > -1}
}

module.exports = AppearanceManager;
