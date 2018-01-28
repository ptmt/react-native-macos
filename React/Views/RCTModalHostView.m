/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTModalHostView.h"

#import <AppKit/AppKit.h>

#import "RCTAssert.h"
#import "RCTBridge.h"
#import "RCTModalHostViewController.h"
#import "RCTTouchHandler.h"
#import "RCTUIManager.h"
#import "RCTUtils.h"
#import "NSView+React.h"

@implementation RCTModalHostView
{
  __weak RCTBridge *_bridge;
  BOOL _isPresented;
  RCTModalHostViewController *_modalViewController;
  RCTTouchHandler *_touchHandler;
  NSView *_reactSubview;
}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithFrame:(CGRect)frame)
RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:coder)

- (instancetype)initWithBridge:(RCTBridge *)bridge
{
  if ((self = [super initWithFrame:CGRectZero])) {
    _bridge = bridge;
    _modalViewController = [[RCTModalHostViewController alloc] initWithNibName:nil bundle:nil];

    NSRect windowFrame = [NSApp mainWindow].frame;
    NSRect frame = NSMakeRect(windowFrame.origin.x, windowFrame.origin.y,
                              windowFrame.size.width, windowFrame.size.height - 100);

    _containerView = [[NSView alloc] initWithFrame:frame];
    _containerView.autoresizingMask = NSViewMaxXMargin | NSViewMaxYMargin;
    _modalViewController.view = _containerView;
    _modalViewController.title = [NSApp mainWindow].title;
    _touchHandler = [[RCTTouchHandler alloc] initWithBridge:bridge];
    _isPresented = NO;

    __weak typeof(self) weakSelf = self;
    _modalViewController.boundsDidChangeBlock = ^(CGRect newBounds) {
      [weakSelf notifyForBoundsChange:newBounds];
    };
    _modalViewController.initCompletionHandler = ^(NSWindow *modal) {
      modal.delegate = weakSelf;
    };
    _modalViewController.closeCompletionHandler = ^{
      [self dismissModalViewController];
    };
  }

  return self;
}

- (void)notifyForBoundsChange:(CGRect)newBounds
{
  if (_reactSubview && _isPresented) {
    [_bridge.uiManager setSize:newBounds.size forView:_reactSubview];
  }
}

- (void)insertReactSubview:(NSView *)subview atIndex:(NSInteger)atIndex
{
  RCTAssert(_reactSubview == nil, @"Modal view can only have one subview");
  [super insertReactSubview:subview atIndex:atIndex];
  [subview addGestureRecognizer:_touchHandler];
  subview.autoresizingMask = NSViewMaxXMargin | NSViewMaxYMargin;

  [_modalViewController.view addSubview:subview];
  _reactSubview = subview;
}

- (void)removeReactSubview:(NSView *)subview
{
  RCTAssert(subview == _reactSubview, @"Cannot remove view other than modal view");
  [super removeReactSubview:subview];
  [_touchHandler detachFromView:subview];
  _reactSubview = nil;
}

- (void)didUpdateReactSubviews
{
  // Do nothing, as subview (singular) is managed by `insertReactSubview:atIndex:`
}

- (void)dismissModalViewController
{
  if (_isPresented) {
    // [self.reactViewController dismissViewController:_modalViewController];
    _isPresented = NO;
    _onRequestClose(nil);
  }
}

- (void)viewDidMoveToWindow
{
  [super viewDidMoveToWindow];
  if (!_isPresented && self.window) {
    RCTAssert(self.reactViewController, @"Can't present modal view controller without a presenting view controller");

    if ([self.presentationType isEqualToString:@"window"]) {
      [self.reactViewController presentViewControllerAsModalWindow:_modalViewController];
      [NSApp modalWindow].delegate = self;
    } else if ([self.presentationType isEqualToString:@"sheet"]) {
      [self.reactViewController presentViewControllerAsSheet:_modalViewController];
    } else if ([self.presentationType isEqualToString:@"popover"]) {
      // TODO: Pass the real positioning view
      [self.reactViewController presentViewController:_modalViewController
          asPopoverRelativeToRect:self.frame
                           ofView:self
                    preferredEdge:NSMinYEdge
                         behavior:NSPopoverBehaviorTransient];
    }

    if (_onShow) {
      _onShow(nil);
    }

    _isPresented = YES;
  }
}

- (void)viewDidMoveToSuperview
{
  [super viewDidMoveToSuperview];

  if (_isPresented && !self.superview) {
    [self dismissModalViewController];
  }
}

- (void)invalidate
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [self dismissModalViewController];
  });
}

- (BOOL)isTransparent
{
  return YES; //return _modalViewController.modalPresentationStyle == UIModalPresentationCustom;
}

- (BOOL)hasAnimationType
{
  return ![self.animationType isEqualToString:@"none"];
}

- (void)setTransparent:(BOOL)transparent
{
  //  _modalViewController.modalPresentationStyle = transparent ? UIModalPresentationCustom : UIModalPresentationFullScreen;
}

- (void)setWidth:(NSNumber *)width
{
  NSRect frame = self.containerView.frame;
  [self.containerView setFrame:NSMakeRect(frame.origin.x, frame.origin.y, width.floatValue, frame.size.height)];
}

- (void)setHeight:(NSNumber *)height
{
  NSRect frame = self.containerView.frame;
  [self.containerView setFrame:NSMakeRect(frame.origin.x, frame.origin.y, frame.size.width, height.floatValue)];
}

- (BOOL)windowShouldClose:(NSNotification *)notification
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [self dismissModalViewController];
  });
  return NO;
}

@end
