/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTScrollView.h"

#import <AppKit/AppKit.h>

#import "RCTConvert.h"
#import "RCTEventDispatcher.h"
#import "RCTLog.h"
#import "RCTUIManager.h"
#import "RCTUtils.h"
#import "NSView+Private.h"
#import "NSView+React.h"

CGFloat const ZINDEX_DEFAULT = 0;
CGFloat const ZINDEX_STICKY_HEADER = 50;

@interface RCTScrollEvent : NSObject <RCTEvent>

- (instancetype)initWithType:(RCTScrollEventType)type
                    reactTag:(NSNumber *)reactTag
                  scrollView:(NSScrollView *)scrollView
                    userData:(NSDictionary *)userData
               coalescingKey:(uint16_t)coalescingKey NS_DESIGNATED_INITIALIZER;

@end

@implementation RCTScrollEvent
{
  RCTScrollEventType _type;
  NSScrollView *_scrollView;
  NSDictionary *_userData;
  uint16_t _coalescingKey;
}

@synthesize viewTag = _viewTag;

- (instancetype)initWithType:(RCTScrollEventType)type
                    reactTag:(NSNumber *)reactTag
                  scrollView:(NSScrollView *)scrollView
                    userData:(NSDictionary *)userData
               coalescingKey:(uint16_t)coalescingKey
{
  RCTAssertParam(reactTag);

  if ((self = [super init])) {
    _type = type;
    _viewTag = reactTag;
    _scrollView = scrollView;
    _userData = userData;
    _coalescingKey = coalescingKey;

  }
  return self;
}

- (uint16_t)coalescingKey
{
  return _coalescingKey;
}

RCT_NOT_IMPLEMENTED(- (instancetype)init)

- (NSDictionary *)body
{
  NSDictionary *body = @{
    @"contentOffset": @{
      @"x": @([[_scrollView contentView] documentVisibleRect].origin.x),
      @"y": @([[_scrollView contentView] documentVisibleRect].origin.y)
    },
    @"contentInset": @{
      @"top": @(_scrollView.contentInsets.top),
      @"left": @(_scrollView.contentInsets.left),
      @"bottom": @(_scrollView.contentInsets.bottom),
      @"right": @(_scrollView.contentInsets.right)
    },
    @"contentSize": @{
      @"width": @([[_scrollView documentView] bounds].size.width),
      @"height": @([[_scrollView documentView] bounds].size.height)
    },
    @"layoutMeasurement": @{
      @"width": @(_scrollView.frame.size.width),
      @"height": @(_scrollView.frame.size.height)
    },
    @"zoomScale": @(1),
  };

  if (_userData) {
    NSMutableDictionary *mutableBody = [body mutableCopy];
    [mutableBody addEntriesFromDictionary:_userData];
    body = mutableBody;
  }

  return body;
}

- (NSString *)eventName
{
  static NSString *events[] = {
    @"scrollBeginDrag",
    @"scroll",
    @"scrollEndDrag",
    @"momentumScrollBegin",
    @"momentumScrollEnd",
    @"scrollAnimationEnd",
  };

  return events[_type];
}

- (BOOL)canCoalesce
{
  return YES;
}

- (RCTScrollEvent *)coalesceWithEvent:(RCTScrollEvent *)newEvent
{
  NSArray<NSDictionary *> *updatedChildFrames = [_userData[@"updatedChildFrames"] arrayByAddingObjectsFromArray:newEvent->_userData[@"updatedChildFrames"]];

  if (updatedChildFrames) {
    NSMutableDictionary *userData = [newEvent->_userData mutableCopy];
    userData[@"updatedChildFrames"] = updatedChildFrames;
    newEvent->_userData = userData;
  }

  return newEvent;
}

+ (NSString *)moduleDotMethod
{
  return @"RCTEventEmitter.receiveEvent";
}

- (NSArray *)arguments
{
  return @[self.viewTag, RCTNormalizeInputEventName(self.eventName), [self body]];
}

@end

@implementation RCTEventDispatcher (RCTNativeScrollView)

- (void)sendFakeScrollEvent:(NSNumber *)reactTag
{
  RCTScrollEvent *fakeScrollEvent = [[RCTScrollEvent alloc] initWithType:RCTScrollEventTypeMove
                                                                reactTag:reactTag
                                                              scrollView:nil
                                                                userData:nil
                                                           coalescingKey:0];
  [self sendEvent:fakeScrollEvent];
}
@end


@implementation RCTNativeScrollView
{
  NSColor * _backgroundColor;
  BOOL _autoScrollToBottom;
  BOOL _inAutoScrollToBottom;
  RCTEventDispatcher *_eventDispatcher;
  NSRect _oldDocumentFrame;
  NSMutableArray *_cachedChildFrames;
  NSTimeInterval _lastScrollDispatchTime;
  BOOL _allowNextScrollNoMatterWhat;
  CGRect _lastClippedToRect;
  uint16_t _coalescingKey;

}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithFrame:(CGRect)frame)
RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:(NSCoder *)aDecoder)

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
  if ((self = [super initWithFrame:CGRectZero])) {
    _backgroundColor = [NSColor clearColor];
    _eventDispatcher = eventDispatcher;
    [self setDrawsBackground:NO];

    [self.contentView setPostsBoundsChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter]
                                  addObserver:self
                                  selector:@selector(boundsDidChange:)
                                  name:NSViewBoundsDidChangeNotification
                                  object:self.contentView];

    _scrollEventThrottle = 0.0;
    _lastScrollDispatchTime = CACurrentMediaTime();
    _cachedChildFrames = [NSMutableArray new];
    _lastClippedToRect = CGRectNull;

  }
  return self;
}

- (void)insertReactSubview:(NSView *)view atIndex:(__unused NSInteger)atIndex
{
  [self setDocumentView:view];
  if (_autoScrollToBottom) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(documentFrameDidChange:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:view];

    [self scrollToBottom];
  }
}

- (void)setAutoScrollToBottom:(BOOL)autoScrollToBottom
{
  _autoScrollToBottom = autoScrollToBottom;
  [self setDocumentView:[self documentView]];
  [self setFrame:[self frame]];
}


- (void)setFrame:(NSRect)frameRect
{
  BOOL autoScroll = NO;

  if (_autoScrollToBottom) {
    NSRect	documentVisibleRect = [self documentVisibleRect];
    NSRect	documentFrame = [[self documentView] frame];

    //Autoscroll if we're scrolled close to the bottom
    autoScroll = ((documentVisibleRect.origin.y + documentVisibleRect.size.height) > (documentFrame.size.height - 20));
  }

  [super setFrame:frameRect];

  if (autoScroll) {
    [self scrollToBottom];
  }
}

//When our document resizes
- (void)documentFrameDidChange:(__unused NSNotification *)notification
{
  //We guard against a recursive call to this method, which may occur if the user is resizing the view at the same time
  //content is being modified
  if (_autoScrollToBottom && !_inAutoScrollToBottom) {
    NSRect	documentVisibleRect =  [self documentVisibleRect];
    NSRect	   newDocumentFrame = [[self documentView] frame];

    //We autoscroll if the height of the document frame changed AND (Using the old frame to calculate) we're scrolled close to the bottom.
    if ((newDocumentFrame.size.height != _oldDocumentFrame.size.height) &&
        ((documentVisibleRect.origin.y + documentVisibleRect.size.height) > (_oldDocumentFrame.size.height - 20))) {
      _inAutoScrollToBottom = YES;
      [self scrollToBottom];
      _inAutoScrollToBottom = NO;
    }

    //Remember the new frame
    _oldDocumentFrame = newDocumentFrame;
  }
}

- (NSArray *)calculateChildFramesData
{
  NSMutableArray *updatedChildFrames = [NSMutableArray new];
  [[_contentView reactSubviews] enumerateObjectsUsingBlock:
   ^(NSView *subview, NSUInteger idx, __unused BOOL *stop) {

     // Check if new or changed
     CGRect newFrame = subview.frame;
     BOOL frameChanged = NO;
     if (_cachedChildFrames.count <= idx) {
       frameChanged = YES;
       //[_cachedChildFrames addObject:[NSValue valueWithCGRect:newFrame]];
     } else if (!CGRectEqualToRect(newFrame, [_cachedChildFrames[idx] CGRectValue])) {
       frameChanged = YES;
       //_cachedChildFrames[idx] = [NSValue valueWithCGRect:newFrame];
     }

     // Create JS frame object
     if (frameChanged) {
       [updatedChildFrames addObject: @{
                                        @"index": @(idx),
                                        @"x": @(newFrame.origin.x),
                                        @"y": @(newFrame.origin.y),
                                        @"width": @(newFrame.size.width),
                                        @"height": @(newFrame.size.height),
                                        }];
     }
   }];

  return updatedChildFrames;
}

- (void)scrollToBottom
{
  [[self documentView] scrollPoint:NSMakePoint(0, 100000)]; // TODO: avoid this hack
}

- (BOOL)opaque
{
  return NO;
}

- (void)setShowsVerticalScrollIndicator:(BOOL)value
{
  self.hasVerticalScroller = value;
}

- (void)setShowsHorizontalScrollIndicator:(BOOL)value
{
  self.hasHorizontalScroller = value;
}

- (void)removeReactSubview:(NSView *)subview
{
  [subview removeFromSuperview];
}


- (BOOL)isFlipped
{
  return YES;
}

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
  if ([_backgroundColor isEqual:backgroundColor] || backgroundColor == NULL) {
    return;
  }
  _backgroundColor = backgroundColor;

  if (![self wantsLayer]) {
    CALayer *viewLayer = [CALayer layer];
    [viewLayer setBackgroundColor:[backgroundColor CGColor]];
    [self setLayer:viewLayer];
    [self setWantsLayer:YES];
  } else {
    [self.layer setBackgroundColor:[backgroundColor CGColor]];
  }
  [self setNeedsDisplay:YES];
}

- (void)updateClippedSubviews
{
  // Find a suitable view to use for clipping
  NSView *clipView = [self react_findClipView];
  if (!clipView) {
    return;
  }

  static const CGFloat leeway = 1.0;

  const CGSize contentSize = [[self documentView] bounds].size;
  const CGRect bounds = [[self contentView] bounds];
  const BOOL scrollsHorizontally = contentSize.width > bounds.size.width;
  const BOOL scrollsVertically = contentSize.height > bounds.size.height;
  const BOOL shouldClipAgain =
  CGRectIsNull(_lastClippedToRect) ||
  (scrollsHorizontally && (bounds.size.width < leeway || fabs(_lastClippedToRect.origin.x - bounds.origin.x) >= leeway)) ||
  (scrollsVertically && (bounds.size.height < leeway || fabs(_lastClippedToRect.origin.y - bounds.origin.y) >= leeway));

  if (shouldClipAgain) {
    const CGRect clipRect = CGRectInset(clipView.bounds, -leeway, -leeway);
   // NSLog(@"clipRect %f %f", [[self contentView] bounds].size.height, [[self contentView] bounds].origin.y);

    [self react_updateClippedSubviewsWithClipRect:clipRect relativeToView:clipView];
    _lastClippedToRect = bounds;
  }
}

- (void)boundsDidChange:(__unused NSEvent *)theEvent
{
   //[_scrollView dockClosestSectionHeader];
  [self updateClippedSubviews];
  NSTimeInterval now = CACurrentMediaTime();

  /**
   * TODO: this logic looks wrong, and it may be because it is. Currently, if _scrollEventThrottle
   * is set to zero (the default), the "didScroll" event is only sent once per scroll, instead of repeatedly
   * while scrolling as expected. However, if you "fix" that bug, ScrollView will generate repeated
   * warnings, and behave strangely (ListView works fine however), so don't fix it unless you fix that too!
   */
  if (_scrollEventThrottle == 0 ||
        (_scrollEventThrottle > 0 && _scrollEventThrottle < (now - _lastScrollDispatchTime))) {

    // Calculate changed frames
    NSArray *childFrames = [self calculateChildFramesData];

    RCTScrollEvent *scrollEvent = [[RCTScrollEvent alloc] initWithType:RCTScrollEventTypeMove
                                                              reactTag:self.reactTag
                                                            scrollView:self
                                                              userData:@{@"updatedChildFrames": childFrames}
                                                         coalescingKey:_coalescingKey];
    // Dispatch event
    [_eventDispatcher sendEvent:scrollEvent];

    // Update dispatch time
    _lastScrollDispatchTime = now;
    _allowNextScrollNoMatterWhat = NO;
  }

}


@end
