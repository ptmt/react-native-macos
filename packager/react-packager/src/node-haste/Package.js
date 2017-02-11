'use strict';

const isAbsolutePath = require('absolute-path');
const path = require('./fastpath');

class Package {

  constructor({ file, fastfs, cache }) {
    this.path = path.resolve(file);
    this.root = path.dirname(this.path);
    this._fastfs = fastfs;
    this.type = 'Package';
    this._cache = cache;
  }

  getMain() {
    return this.read().then(json => {
      var replacements = getReplacements(json);
      if (typeof replacements === 'string') {
        return path.join(this.root, replacements);
      }

      let main = json.main || 'index';

      if (replacements && typeof replacements === 'object') {
        main = replacements[main] ||
          replacements[main + '.js'] ||
          replacements[main + '.json'] ||
          replacements[main.replace(/(\.js|\.json)$/, '')] ||
          main;
      }

      return path.join(this.root, main);
    });
  }

  isHaste() {
    return this._cache.get(this.path, 'package-haste', () =>
      this.read().then(json => !!json.name)
    );
  }

  getName() {
    return this._cache.get(this.path, 'package-name', () =>
      this.read().then(json => json.name)
    );
  }

  invalidate() {
    this._cache.invalidate(this.path);
  }

  redirectRequire(name) {
    return this.read().then(json => {
      var replacements = getReplacements(json);

      if (!replacements || typeof replacements !== 'object') {
        return name;
      }

      if (name[0] !== '/') {
        const replacement = replacements[name];
        // support exclude with "someDependency": false
        return replacement === false
          ? false
          : replacement || name;
      }

      if (!isAbsolutePath(name)) {
        throw new Error(`Expected ${name} to be absolute path`);
      }

      const relPath = './' + path.relative(this.root, name);
      let redirect = replacements[relPath];

      // false is a valid value
      if (redirect == null) {
        redirect = replacements[relPath + '.js'];
        if (redirect == null) {
          redirect = replacements[relPath + '.json'];
        }
      }

      // support exclude with "./someFile": false
      if (redirect === false) {
        return false;
      }

      if (redirect) {
        return path.join(
          this.root,
          redirect
        );
      }

      return name;
    });
  }

  read() {
    if (!this._reading) {
      this._reading = this._fastfs.readFile(this.path)
        .then(jsonStr => JSON.parse(jsonStr));
    }

    return this._reading;
  }
}

function getReplacements(pkg) {
  let rnm = pkg['react-native-macos'];
  let rn = pkg['react-native'];
  let browser = pkg.browser;
  
  if (rnm == null && rn == null) {
    return browser;
  }
  
  if (rnm == null && browser == null) {
    return rn;
  }

  if (rn == null && browser == null) {
    return rnm;
  }

  if (typeof rnm === 'string') {
    rnm = { [pkg.main]: rnm };
  }

  if (typeof rn === 'string') {
    rn = { [pkg.main]: rn };
  }

  if (typeof browser === 'string') {
    browser = { [pkg.main]: browser };
  }

  // merge with "browser" as default,
  // "react-native" as override 1
  // "react-native-macos" as override 2
  return { ...browser, ...rn, ...rnm };
}

module.exports = Package;
