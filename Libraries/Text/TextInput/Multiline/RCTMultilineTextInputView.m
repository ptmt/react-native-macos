/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTMultilineTextInputView.h"

#import <React/RCTUtils.h>
#import <React/NSView+React.h>

#import "RCTUITextView.h"

@interface RCTMultilineTextInputView () <RCTTextScrollViewDelegate>
@end

@implementation RCTMultilineTextInputView
{
  RCTUITextView *_backedTextInputView;
  RCTTextScrollView *_scrollView;
}

- (instancetype)initWithBridge:(RCTBridge *)bridge
{
  if (self = [super initWithBridge:bridge]) {
    // `blurOnSubmit` defaults to `false` for <TextInput multiline={true}> by design.
    self.blurOnSubmit = NO;

    _backedTextInputView = [[RCTUITextView alloc] initWithFrame:self.bounds];
    _backedTextInputView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _backedTextInputView.backgroundColor = [NSColor clearColor];
    _backedTextInputView.textColor = [NSColor blackColor];
    // This line actually removes 5pt (default value) left and right padding in UITextView.
    _backedTextInputView.textContainer.lineFragmentPadding = 0;
    _backedTextInputView.textInputDelegate = self;

    _scrollView = [[RCTTextScrollView alloc] initWithFrame:NSZeroRect];
    _scrollView.documentView = _backedTextInputView;
    _scrollView.delegate = self;

    [self addSubview:_scrollView];
  }

  return self;
}

- (void)setFrame:(NSRect)frame
{
  [super setFrame:frame];
  _scrollView.frameSize = frame.size;
}

- (void)setReactBorderInsets:(NSEdgeInsets)reactBorderInsets
{
  [super setReactBorderInsets:reactBorderInsets];
  _scrollView.contentInsets = self.reactCompoundInsets;
}

- (void)setReactPaddingInsets:(NSEdgeInsets)reactPaddingInsets
{
  [super setReactPaddingInsets:reactPaddingInsets];
  _scrollView.contentInsets = self.reactCompoundInsets;
}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithFrame:(CGRect)frame)
RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:(NSCoder *)coder)

- (id<RCTBackedTextInputViewProtocol>)backedTextInputView
{
  return _backedTextInputView;
}

#pragma mark - NSScrollViewDelegate

- (void)scrollViewDidScroll:(RCTTextScrollView *)scrollView
{
  RCTDirectEventBlock onScroll = self.onScroll;

  if (onScroll) {
    NSSize size = scrollView.bounds.size;
    NSSize contentSize = scrollView.contentSize;
    NSPoint contentOffset = scrollView.contentOffset;
    NSEdgeInsets contentInset = scrollView.contentInsets;

    onScroll(@{
      @"contentOffset": @{
        @"x": @(contentOffset.x),
        @"y": @(contentOffset.y)
      },
      @"contentInset": @{
        @"top": @(contentInset.top),
        @"left": @(contentInset.left),
        @"bottom": @(contentInset.bottom),
        @"right": @(contentInset.right)
      },
      @"contentSize": @{
        @"width": @(contentSize.width),
        @"height": @(contentSize.height)
      },
      @"layoutMeasurement": @{
        @"width": @(size.width),
        @"height": @(size.height)
      },
      @"zoomScale": @(1),
      @"target": self.reactTag,
    });
  }
}

@end

@implementation RCTTextScrollView

- (instancetype)initWithFrame:(NSRect)frame
{
  if (self = [super initWithFrame:frame]) {
    self.drawsBackground = NO;
    self.hasVerticalScroller = YES;
    self.automaticallyAdjustsContentInsets = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_didScroll)
                                                 name:NSViewBoundsDidChangeNotification
                                               object:self.contentView];
  }

  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSPoint)contentOffset
{
  return self.contentView.bounds.origin;
}

- (void)_didScroll
{
  [self.delegate scrollViewDidScroll:self];
}

@end
