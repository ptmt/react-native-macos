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

- (instancetype)initWithEventName:(NSString *)eventName
                         reactTag:(NSNumber *)reactTag
                       scrollView:(NSScrollView *)scrollView
                         userData:(NSDictionary *)userData
                    coalescingKey:(uint16_t)coalescingKey NS_DESIGNATED_INITIALIZER;

@end

@implementation RCTScrollEvent
{
  NSScrollView *_scrollView;
  NSDictionary *_userData;
  uint16_t _coalescingKey;
}

@synthesize viewTag = _viewTag;
@synthesize eventName = _eventName;

- (instancetype)initWithEventName:(NSString *)eventName
                         reactTag:(NSNumber *)reactTag
                       scrollView:(NSScrollView *)scrollView
                         userData:(NSDictionary *)userData
                    coalescingKey:(uint16_t)coalescingKey
{
  RCTAssertParam(reactTag);

  if ((self = [super init])) {
    _eventName = [eventName copy];
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
  // Use the selector here in case the onScroll block property is ever renamed
  NSString *eventName = NSStringFromSelector(@selector(onScroll));
  RCTScrollEvent *fakeScrollEvent = [[RCTScrollEvent alloc] initWithEventName:eventName
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
  NSHashTable *_scrollListeners;
  NSString *_lastEmittedEventName;
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
    [self setWantsLayer:YES];
    [self.layer setBackgroundColor:[backgroundColor CGColor]];
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

- (void)setContentInset:(NSEdgeInsets)contentInset
{
  CGPoint contentOffset = self.documentVisibleRect.origin;

  self.contentInsets = contentInset;
//  [RCTView autoAdjustInsetsForView:self
//                    withScrollView:_scrollView
//                      updateOffset:NO];

  [self.documentView setFrameOrigin:contentOffset];
}

- (void)scrollToOffset:(CGPoint)offset
{
  [self scrollToOffset:offset animated:YES];
}

- (void)scrollToOffset:(CGPoint)offset animated:(BOOL)animated
{
  if (!CGPointEqualToPoint(self.documentVisibleRect.origin, offset)) {
    // Ensure at least one scroll event will fire
    _allowNextScrollNoMatterWhat = YES;
    [self.documentView scrollPoint:offset];
  }
}

- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated
{
  // Not implemented
  //[_scrollView zoomToRect:rect animated:animated];
}

- (void)refreshContentInset
{
  [RCTView autoAdjustInsetsForView:self
                    withScrollView:self
                      updateOffset:YES];
}

#pragma mark - ScrollView delegate

#define RCT_SEND_SCROLL_EVENT(_eventName, _userData) { \
  NSString *eventName = NSStringFromSelector(@selector(_eventName)); \
  [self sendScrollEventWithName:eventName scrollView:self userData:_userData]; \
}

#define RCT_FORWARD_SCROLL_EVENT(call) \
for (NSObject<UIScrollViewDelegate> *scrollViewListener in _scrollListeners) { \
  if ([scrollViewListener respondsToSelector:_cmd]) { \
    [scrollViewListener call]; \
  } \
}

#define RCT_SCROLL_EVENT_HANDLER(delegateMethod, eventName) \
- (void)delegateMethod:(NSScrollView *)scrollView           \
{                                                           \
  RCT_SEND_SCROLL_EVENT(eventName, nil);                    \
  RCT_FORWARD_SCROLL_EVENT(delegateMethod:scrollView);      \
}

//RCT_SCROLL_EVENT_HANDLER(scrollViewWillBeginDecelerating, onMomentumScrollBegin)
//RCT_SCROLL_EVENT_HANDLER(scrollViewDidZoom, onScroll)

- (void)addScrollListener:(NSObject<NSScrollViewDelegate> *)scrollListener
{
  [_scrollListeners addObject:scrollListener];
}

- (void)removeScrollListener:(NSObject<NSScrollViewDelegate> *)scrollListener
{
  [_scrollListeners removeObject:scrollListener];
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

    // Dispatch event
    RCT_SEND_SCROLL_EVENT(onScroll, (@{@"updatedChildFrames": childFrames}));

    // Update dispatch time
    _lastScrollDispatchTime = now;
    _allowNextScrollNoMatterWhat = NO;
  }

  // TODO: do we need to forward this?
  // RCT_FORWARD_SCROLL_EVENT(scrollViewDidScroll:self);
}

- (void)scrollViewWillBeginDragging:(NSScrollView *)scrollView
{
  _allowNextScrollNoMatterWhat = YES; // Ensure next scroll event is recorded, regardless of throttle
  RCT_SEND_SCROLL_EVENT(onScrollBeginDrag, nil);
  //RCT_FORWARD_SCROLL_EVENT(scrollViewWillBeginDragging:scrollView);
}
//
//- (void)scrollViewWillEndDragging:(NSScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
//{
//  // snapToInterval
//  // An alternative to enablePaging which allows setting custom stopping intervals,
//  // smaller than a full page size. Often seen in apps which feature horizonally
//  // scrolling items. snapToInterval does not enforce scrolling one interval at a time
//  // but guarantees that the scroll will stop at an interval point.
//  if (self.snapToInterval) {
//    CGFloat snapToIntervalF = (CGFloat)self.snapToInterval;
//
//    // Find which axis to snap
//    BOOL isHorizontal = (scrollView.contentSize.width > self.frame.size.width);
//
//    // What is the current offset?
//    CGFloat targetContentOffsetAlongAxis = isHorizontal ? targetContentOffset->x : targetContentOffset->y;
//
//    // Which direction is the scroll travelling?
//    CGPoint translation = [scrollView.panGestureRecognizer translationInView:scrollView];
//    CGFloat translationAlongAxis = isHorizontal ? translation.x : translation.y;
//
//    // Offset based on desired alignment
//    CGFloat frameLength = isHorizontal ? self.frame.size.width : self.frame.size.height;
//    CGFloat alignmentOffset = 0.0f;
//    if ([self.snapToAlignment  isEqualToString: @"center"]) {
//      alignmentOffset = (frameLength * 0.5f) + (snapToIntervalF * 0.5f);
//    } else if ([self.snapToAlignment  isEqualToString: @"end"]) {
//      alignmentOffset = frameLength;
//    }
//
//    // Pick snap point based on direction and proximity
//    NSInteger snapIndex = floor((targetContentOffsetAlongAxis + alignmentOffset) / snapToIntervalF);
//    snapIndex = (translationAlongAxis < 0) ? snapIndex + 1 : snapIndex;
//    CGFloat newTargetContentOffset = ( snapIndex * snapToIntervalF ) - alignmentOffset;
//
//    // Set new targetContentOffset
//    if (isHorizontal) {
//      targetContentOffset->x = newTargetContentOffset;
//    } else {
//      targetContentOffset->y = newTargetContentOffset;
//    }
//  }
//
//  NSDictionary *userData = @{
//    @"velocity": @{
//      @"x": @(velocity.x),
//      @"y": @(velocity.y)
//    },
//    @"targetContentOffset": @{
//      @"x": @(targetContentOffset->x),
//      @"y": @(targetContentOffset->y)
//    }
//  };
//  RCT_SEND_SCROLL_EVENT(onScrollEndDrag, userData);
//  RCT_FORWARD_SCROLL_EVENT(scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset);
//}
//
//- (void)scrollViewDidEndDragging:(NSScrollView *)scrollView willDecelerate:(BOOL)decelerate
//{
//  RCT_FORWARD_SCROLL_EVENT(scrollViewDidEndDragging:scrollView willDecelerate:decelerate);
//}
//
//- (void)scrollViewWillBeginZooming:(NSScrollView *)scrollView withView:(NSView *)view
//{
//  RCT_SEND_SCROLL_EVENT(onScrollBeginDrag, nil);
//  RCT_FORWARD_SCROLL_EVENT(scrollViewWillBeginZooming:scrollView withView:view);
//}
//
//- (void)scrollViewDidEndZooming:(NSScrollView *)scrollView withView:(NSView *)view atScale:(CGFloat)scale
//{
//  RCT_SEND_SCROLL_EVENT(onScrollEndDrag, nil);
//  RCT_FORWARD_SCROLL_EVENT(scrollViewDidEndZooming:scrollView withView:view atScale:scale);
//}
//
//- (void)scrollViewDidEndDecelerating:(NSScrollView *)scrollView
//{
//  // Fire a final scroll event
//  _allowNextScrollNoMatterWhat = YES;
//  [self scrollViewDidScroll:scrollView];
//
//  // Fire the end deceleration event
//  RCT_SEND_SCROLL_EVENT(onMomentumScrollEnd, nil);
//  RCT_FORWARD_SCROLL_EVENT(scrollViewDidEndDecelerating:scrollView);
//}
//
//- (void)scrollViewDidEndScrollingAnimation:(NSScrollView *)scrollView
//{
//  // Fire a final scroll event
//  _allowNextScrollNoMatterWhat = YES;
//  [self scrollViewDidScroll:scrollView];
//
//  // Fire the end deceleration event
//  RCT_SEND_SCROLL_EVENT(onMomentumScrollEnd, nil); //TODO: shouldn't this be onScrollAnimationEnd?
//  RCT_FORWARD_SCROLL_EVENT(scrollViewDidEndScrollingAnimation:scrollView);
//}
//
//- (BOOL)scrollViewShouldScrollToTop:(NSScrollView *)scrollView
//{
//  if ([_nativeScrollDelegate respondsToSelector:_cmd]) {
//    return [_nativeScrollDelegate scrollViewShouldScrollToTop:scrollView];
//  }
//  return YES;
//}

- (NSView *)viewForZoomingInScrollView:(__unused NSScrollView *)scrollView
{
  return _contentView;
}

#pragma mark - Setters

- (CGSize)_calculateViewportSize
{
  CGSize viewportSize = self.bounds.size;
  if (_automaticallyAdjustContentInsets) {
    NSEdgeInsets contentInsets = [RCTView contentInsetsForView:self];
    viewportSize = CGSizeMake(self.bounds.size.width - contentInsets.left - contentInsets.right,
                                self.bounds.size.height - contentInsets.top - contentInsets.bottom);
  }
  return viewportSize;
}

- (CGPoint)calculateOffsetForContentSize:(CGSize)newContentSize
{
  CGPoint oldOffset = self.documentVisibleRect.origin;
  CGPoint newOffset = oldOffset;

  CGSize oldContentSize = self.contentSize;
  CGSize viewportSize = [self _calculateViewportSize];

  BOOL fitsinViewportY = oldContentSize.height <= viewportSize.height && newContentSize.height <= viewportSize.height;
  if (newContentSize.height < oldContentSize.height && !fitsinViewportY) {
    CGFloat offsetHeight = oldOffset.y + viewportSize.height;
    if (oldOffset.y < 0) {
      // overscrolled on top, leave offset alone
    } else if (offsetHeight > oldContentSize.height) {
      // overscrolled on the bottom, preserve overscroll amount
      newOffset.y = MAX(0, oldOffset.y - (oldContentSize.height - newContentSize.height));
    } else if (offsetHeight > newContentSize.height) {
      // offset falls outside of bounds, scroll back to end of list
      newOffset.y = MAX(0, newContentSize.height - viewportSize.height);
    }
  }

  BOOL fitsinViewportX = oldContentSize.width <= viewportSize.width && newContentSize.width <= viewportSize.width;
  if (newContentSize.width < oldContentSize.width && !fitsinViewportX) {
    CGFloat offsetHeight = oldOffset.x + viewportSize.width;
    if (oldOffset.x < 0) {
      // overscrolled at the beginning, leave offset alone
    } else if (offsetHeight > oldContentSize.width && newContentSize.width > viewportSize.width) {
      // overscrolled at the end, preserve overscroll amount as much as possible
      newOffset.x = MAX(0, oldOffset.x - (oldContentSize.width - newContentSize.width));
    } else if (offsetHeight > newContentSize.width) {
      // offset falls outside of bounds, scroll back to end
      newOffset.x = MAX(0, newContentSize.width - viewportSize.width);
    }
  }

  // all other cases, offset doesn't change
  return newOffset;
}

- (void)reactBridgeDidFinishTransaction
{
  CGSize contentSize = self.contentSize;

  // TODO: now it doesnt make sense
  if (!CGSizeEqualToSize(self.contentSize, contentSize)) {
    // When contentSize is set manually, ScrollView internals will reset
    // contentOffset to  {0, 0}. Since we potentially set contentSize whenever
    // anything in the ScrollView updates, we workaround this issue by manually
    // adjusting contentOffset whenever this happens
    CGPoint newOffset = [self calculateOffsetForContentSize:contentSize];
    [self.contentView setFrameSize:contentSize];
    [self.documentView setFrameOrigin:newOffset];
  }
}

// Note: setting several properties of UIScrollView has the effect of
// resetting its contentOffset to {0, 0}. To prevent this, we generate
// setters here that will record the contentOffset beforehand, and
// restore it after the property has been set.

#define RCT_SET_AND_PRESERVE_OFFSET(setter, getter, type) \
- (void)setter:(type)value                                \
{                                                         \
  CGPoint contentOffset = _scrollView.contentOffset;      \
  [_scrollView setter:value];                             \
  _scrollView.contentOffset = contentOffset;              \
}                                                         \
- (type)getter                                            \
{                                                         \
  return [_scrollView getter];                            \
}

- (void)sendScrollEventWithName:(NSString *)eventName
                     scrollView:(NSScrollView *)scrollView
                       userData:(NSDictionary *)userData
{
  if (![_lastEmittedEventName isEqualToString:eventName]) {
    _coalescingKey++;
    _lastEmittedEventName = [eventName copy];
  }
  RCTScrollEvent *scrollEvent = [[RCTScrollEvent alloc] initWithEventName:eventName
                                                                 reactTag:self.reactTag
                                                               scrollView:scrollView
                                                                 userData:userData
                                                            coalescingKey:_coalescingKey];
  [_eventDispatcher sendEvent:scrollEvent];
}

@end

@implementation RCTEventDispatcher (RCTScrollView)

- (void)sendFakeScrollEvent:(NSNumber *)reactTag
{
  // Use the selector here in case the onScroll block property is ever renamed
  NSString *eventName = NSStringFromSelector(@selector(onScroll));
  RCTScrollEvent *fakeScrollEvent = [[RCTScrollEvent alloc] initWithEventName:eventName
                                                                     reactTag:reactTag
                                                                   scrollView:nil
                                                                     userData:nil
                                                                coalescingKey:0];
  [self sendEvent:fakeScrollEvent];
}

@end
