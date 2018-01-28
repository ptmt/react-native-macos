/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "UpdatePropertiesExampleView.h"

#import <React/RCTRootView.h>
#import <React/RCTViewManager.h>

#import "AppDelegate.h"

@interface UpdatePropertiesExampleViewManager : RCTViewManager

@end

@implementation UpdatePropertiesExampleViewManager

RCT_EXPORT_MODULE();

- (NSView *)view
{
  return [UpdatePropertiesExampleView new];
}

@end

@implementation UpdatePropertiesExampleView
{
  RCTRootView *_rootView;
  NSButton *_button;
  BOOL _beige;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    _beige = YES;

    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];

    _rootView = [[RCTRootView alloc] initWithBridge:appDelegate.bridge
                                         moduleName:@"SetPropertiesExampleApp"
                                  initialProperties:@{@"color":@"beige"}];

    _button = [[NSButton alloc] init];
    [_button setTitle:@"Native Button" ];
    //[_button setT:[NSColor whiteColor]];
    //[_button setBackgroundColor:[NSColor grayColor]];

    [_button setTarget:self];
    [_button setAction:@selector(changeColor)];


    [self addSubview:_button];
    [self addSubview:_rootView];
  }
  return self;
}

- (void)layoutSubviews
{
  float spaceHeight = 20;
  float buttonHeight = 40;
  float rootViewWidth = self.bounds.size.width;
  float rootViewHeight = self.bounds.size.height - spaceHeight - buttonHeight;

  [_rootView setFrame:CGRectMake(0, 0, rootViewWidth, rootViewHeight)];
  [_button setFrame:CGRectMake(0, rootViewHeight + spaceHeight, rootViewWidth, buttonHeight)];
}

- (void)changeColor
{
  _beige = !_beige;
  [_rootView setAppProperties:@{@"color":_beige ? @"beige" : @"purple"}];
}

- (NSArray<NSView<RCTComponent> *> *)reactSubviews
{
  // this is to avoid unregistering our RCTRootView when the component is removed from RN hierarchy
  (void)[super reactSubviews];
  return @[];
}

@end
