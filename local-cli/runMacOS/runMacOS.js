/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */
'use strict';

const child_process = require('child_process');
const fs = require('fs');
const path = require('path');
const findXcodeProject = require('./findXcodeProject');

function runMacOS(argv, config, args) {
  process.chdir(args.projectPath);
  const xcodeProject = findXcodeProject(fs.readdirSync('.'));
  if (!xcodeProject) {
    throw new Error('Could not find Xcode project files in macos folder');
  }

  const inferredSchemeName = path.basename(xcodeProject.name, path.extname(xcodeProject.name));
  const scheme = args.scheme || inferredSchemeName;
  console.log(`Found Xcode ${xcodeProject.isWorkspace ? 'workspace' : 'project'} ${xcodeProject.name}`);

  const xcodebuildArgs = [
    xcodeProject.isWorkspace ? '-workspace' : '-project', xcodeProject.name,
    '-scheme', scheme,
    '-derivedDataPath', 'build',
  ];
  console.log(`Building using "xcodebuild ${xcodebuildArgs.join(' ')}"`);
  child_process.spawnSync('xcodebuild', xcodebuildArgs, {stdio: 'inherit'});

  const appPath = `build/Build/Products/Debug/${inferredSchemeName}.app`;
  console.log(`Launching ${appPath}`);
  child_process.spawnSync('open', [appPath], {stdio: 'inherit'});

  const bundleID = child_process.execFileSync(
    '/usr/libexec/PlistBuddy',
    ['-c', 'Print:CFBundleIdentifier', path.join(appPath, 'Contents', 'Info.plist')],
    {encoding: 'utf8'}
  ).trim();

  console.log(`Launched ${bundleID}`);
}

module.exports = {
  name: 'run-macos',
  description: 'builds your app and starts it',
  func: runMacOS,
  examples: [
    {
      desc: 'Pass a non-standard location of macOS directory',
      cmd: 'react-native-macos run-macos --project-path "./app/macos"',
    },
  ],
  options: [{
    command: '--scheme [string]',
    description: 'Explicitly set Xcode scheme to use',
  }, {
    command: '--project-path [string]',
    description: 'Path relative to project root where the Xcode project '
    + '(.xcodeproj) lives. The default is \'macos\'.',
    default: 'macos',
  }]
};
