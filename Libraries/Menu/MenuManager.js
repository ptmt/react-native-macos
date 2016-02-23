/*
* @providesModule MenuManager
* @flow
*/
'use strict';

const MenuManager = require('NativeModules').MenuManager;
const RCTDeviceEventEmitter = require('RCTDeviceEventEmitter');

MenuManager.addSubmenu = function(title, items) {
  items.forEach(item => {
    MenuManager.addItemToSubmenu(title, item);
    RCTDeviceEventEmitter.addListener(
      'onKeyPressed_' + item.key,
      item.callback
    );
  });
};

module.exports = MenuManager;
