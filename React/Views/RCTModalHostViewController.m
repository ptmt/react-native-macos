
/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTModalHostViewController.h"

@implementation RCTModalHostViewController
{
  CGRect _lastViewFrame;
}

- (void)viewDidLayout
{
  [super viewDidLayout];

  if (self.initCompletionHandler && [NSApp modalWindow]) {
    self.initCompletionHandler([NSApp modalWindow]);
  }

  if (self.boundsDidChangeBlock && !CGRectEqualToRect(_lastViewFrame, self.view.frame)) {
    self.boundsDidChangeBlock(self.view.bounds);
    _lastViewFrame = self.view.frame;
  }
}

- (void)viewDidDisappear
{
  dispatch_async(dispatch_get_main_queue(), ^{
    self.closeCompletionHandler();
  });
}

@end
