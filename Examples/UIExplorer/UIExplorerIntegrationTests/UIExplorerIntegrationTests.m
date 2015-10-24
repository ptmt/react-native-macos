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
  RCTAssert((version.majorVersion == 10 && version.minorVersion >= 10), @"Tests should be run on OSX 10.10+, found %zd.%zd.%zd", version.majorVersion, version.minorVersion, version.patchVersion);
  _runner = RCTInitRunnerForApp(@"Examples/UIExplorer/UIExplorerIntegrationTests/js/IntegrationTestsApp", nil);
}

#pragma mark Logic Tests

- (void)testTheTester_waitOneFrame
{
  [_runner runTest:_cmd
            module:@"IntegrationTestHarnessTest"
      initialProps:@{@"waitOneFrame": @YES}
  expectErrorBlock:nil];
}

- (void)testTheTester_ExpectError
{
  [_runner runTest:_cmd
            module:@"IntegrationTestHarnessTest"
      initialProps:@{@"shouldThrow": @YES}
  expectErrorRegex:@"because shouldThrow"];
}

// This list should be kept in sync with IntegrationTestsApp.js
RCT_TEST(IntegrationTestHarnessTest)
// RCT_TEST(AsyncStorageTest) -- Disabled until AsyncStorage will be completed
RCT_TEST(TimersTest)
RCT_TEST(AppEventsTest)
// RCT_TEST(ImageSnapshotTest) --Disabled until Snapshot isn't ready
// RCT_TEST(SimpleSnapshotTest)

// Disable due to flakiness: #8686784
//RCT_TEST(LayoutEventsTest)
//RCT_TEST(PromiseTest)

@end
