/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 *
 * @providesModule Vibration
 * @flow
 */
 'use strict';

 var warning = require('fbjs/lib/warning');

 var Vibration = {
   cancel: function() {
     warning('Vibration is not supported on this platform!');
   },
   vibrate: function() {
     warning('Vibration is not supported on this platform!');
   }
 };

 module.exports = Vibration;
