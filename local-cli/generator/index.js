/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */
'use strict';

var path = require('path');
var yeoman = require('yeoman-generator');
var utils = require('../generator-utils');

module.exports = yeoman.generators.NamedBase.extend({
  constructor: function() {
    yeoman.generators.NamedBase.apply(this, arguments);

    this.option('skip-ios', {
      desc: 'Skip generating iOS files',
      type: Boolean,
      defaults: false
    });
    this.option('skip-android', {
      desc: 'Skip generating Android files',
      type: Boolean,
      defaults: false
    });
    this.option('upgrade', {
      desc: 'Specify an upgrade',
      type: Boolean,
      defaults: false
    });

    // this passes command line arguments down to the composed generators
<<<<<<< HEAD
    var args = arguments[0];
    if (!this.options['skip-osx']) {
      this.composeWith('react:osx', {args: args}, {
        local: require.resolve(path.resolve(__dirname, '..', 'generator-osx'))
=======
    var args = {args: arguments[0], options: this.options};
    if (!this.options['skip-ios']) {
      this.composeWith('react:ios', args, {
        local: require.resolve(path.resolve(__dirname, '..', 'generator-ios'))
      });
    }
    if (!this.options['skip-android']) {
      this.composeWith('react:android', args, {
        local: require.resolve(path.resolve(__dirname, '..', 'generator-android'))
>>>>>>> ae45d8bd4cc7b0fc810c3f21dcf2c7188ae3097d
      });
    }
  },

  configuring: function() {
    utils.copyAndReplace(
      this.templatePath('../../../.flowconfig'),
      this.destinationPath('.flowconfig'),
      { 'Libraries\/react-native\/react-native-interface.js' : 'node_modules/react-native-desktop/Libraries/react-native/react-native-interface.js' }
    );

    this.fs.copy(
      this.templatePath('_gitignore'),
      this.destinationPath('.gitignore')
    );
    this.fs.copy(
      this.templatePath('_watchmanconfig'),
      this.destinationPath('.watchmanconfig')
    );
  },

  writing: function() {
<<<<<<< HEAD
    if (!this.options['skip-osx']) {
=======
    if (this.options.upgrade) {
      // never upgrade index.*.js files
      return;
    }
    if (!this.options['skip-ios']) {
      this.fs.copyTpl(
        this.templatePath('index.ios.js'),
        this.destinationPath('index.ios.js'),
        {name: this.name}
      );
    }
    if (!this.options['skip-android']) {
>>>>>>> ae45d8bd4cc7b0fc810c3f21dcf2c7188ae3097d
      this.fs.copyTpl(
        this.templatePath('index.osx.js'),
        this.destinationPath('index.osx.js'),
        {name: this.name}
      );
    }
  }
});
