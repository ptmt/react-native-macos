/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <AppKit/AppKit.h>
#import <XCTest/XCTest.h>

#import <RCTTest/RCTTestRunner.h>

#import "RCTAssert.h"

#define RCT_TEST(name)                  \
- (void)test##name                      \
{                                       \
  [_runner runTest:_cmd module:@#name]; \
}

@interface UIExplorerIntegrationTests : XCTestCase

@end

@implementation UIExplorerIntegrationTests
{
  RCTTestRunner *_runner;
}

- (void)setUp
{

  NSOperatingSystemVersion version = [NSProcessInfo processInfo].operatingSystemVersion;
<<<<<<< HEAD
  RCTAssert((version.majorVersion == 10 && version.minorVersion >= 10), @"Tests should be run on OSX 10.10+, found %zd.%zd.%zd", version.majorVersion, version.minorVersion, version.patchVersion);
  _runner = RCTInitRunnerForApp(@"Examples/UIExplorer/UIExplorerIntegrationTests/js/IntegrationTestsApp", nil);
=======
  RCTAssert((version.majorVersion == 8 && version.minorVersion >= 3) || version.majorVersion >= 9, @"Tests should be run on iOS 8.3+, found %zd.%zd.%zd", version.majorVersion, version.minorVersion, version.patchVersion);
  _runner = RCTInitRunnerForApp(@"IntegrationTests/IntegrationTestsApp", nil);
>>>>>>> ae45d8bd4cc7b0fc810c3f21dcf2c7188ae3097d
}

#pragma mark - Test harness

- (void)testTheTester_waitOneFrame
{
  [_runner runTest:_cmd
            module:@"IntegrationTestHarnessTest"
      initialProps:@{@"waitOneFrame": @YES}
configurationBlock:nil];
}

- (void)testTheTester_ExpectError
{
  [_runner runTest:_cmd
            module:@"IntegrationTestHarnessTest"
      initialProps:@{@"shouldThrow": @YES}
configurationBlock:nil
  expectErrorRegex:@"because shouldThrow"];
}

#pragma mark - JS tests

// This list should be kept in sync with IntegrationTestsApp.js
RCT_TEST(IntegrationTestHarnessTest)
// RCT_TEST(AsyncStorageTest) -- Disabled until AsyncStorage will be completed
RCT_TEST(TimersTest)
RCT_TEST(AppEventsTest)
<<<<<<< HEAD
// RCT_TEST(ImageSnapshotTest) --Disabled until Snapshot isn't ready
// RCT_TEST(SimpleSnapshotTest)
=======
//RCT_TEST(ImageSnapshotTest) // Disabled: #8985988
//RCT_TEST(LayoutEventsTest) // Disabled due to flakiness: #8686784
RCT_TEST(SimpleSnapshotTest)
RCT_TEST(PromiseTest)
>>>>>>> ae45d8bd4cc7b0fc810c3f21dcf2c7188ae3097d


@end
