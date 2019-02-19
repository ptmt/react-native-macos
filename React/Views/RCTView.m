/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTView.h"

#import "RCTAutoInsetsProtocol.h"
#import "RCTBorderDrawing.h"
#import "RCTConvert.h"
#import "RCTLog.h"
#import "RCTUtils.h"
#import "NSView+React.h"
#import "UIImageUtils.h"
#import "RCTI18nUtil.h"

@implementation NSView (RCTViewUnmounting)

- (void)react_remountAllSubviews
{
  // Normal views don't support unmounting, so all
  // this does is forward message to our subviews,
  // in case any of those do support it

  for (NSView *subview in self.subviews) {
    [subview react_remountAllSubviews];
  }
}

- (void)react_updateClippedSubviewsWithClipRect:(CGRect)clipRect relativeToView:(NSView *)clipView
{
  // Even though we don't support subview unmounting
  // we do support clipsToBounds, so if that's enabled
  // we'll update the clipping

  if (self.clipsToBounds && self.subviews.count > 0) {
    clipRect = [clipView convertRect:clipRect toView:self];
    clipRect = CGRectIntersection(clipRect, self.bounds);
    clipView = self;
  }

  // Normal views don't support unmounting, so all
  // this does is forward message to our subviews,
  // in case any of those do support it

  for (NSView *subview in self.subviews) {
    [subview react_updateClippedSubviewsWithClipRect:clipRect relativeToView:clipView];
  }
}

- (NSView *)react_findClipView
{
  NSView *testView = self;
  NSView *clipView = nil;
  CGRect clipRect = self.bounds;

  // We will only look for a clipping view up the view hierarchy until we hit the root view.
  while (testView) {
    if (testView.clipsToBounds) {
      if (clipView) {
        CGRect testRect = [clipView convertRect:clipRect toView:testView];
        if (!CGRectContainsRect(testView.bounds, testRect)) {
          clipView = testView;
          clipRect = CGRectIntersection(testView.bounds, testRect);
        }
      } else {
        clipView = testView;
        clipRect = [self convertRect:self.bounds toView:clipView];
      }
    }
    if ([testView isReactRootView]) {
      break;
    }
    testView = testView.superview;
  }
  return clipView ?: self.window.contentView;
}

@end

static NSString *RCTRecursiveAccessibilityLabel(NSView *view)
{
  NSMutableString *str = [NSMutableString stringWithString:@""];
  for (NSView *subview in view.subviews) {
    NSString *label = subview.accessibilityLabel;
    if (!label) {
      label = RCTRecursiveAccessibilityLabel(subview);
    }
    if (label && label.length > 0) {
      if (str.length > 0) {
        [str appendString:@" "];
      }
      [str appendString:label];
    }
  }
  return str;
}

@implementation RCTView
{
  NSColor *_backgroundColor;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    _borderWidth = -1;
    _borderTopWidth = -1;
    _borderRightWidth = -1;
    _borderBottomWidth = -1;
    _borderLeftWidth = -1;
    _borderStartWidth = -1;
    _borderEndWidth = -1;
    _borderTopLeftRadius = -1;
    _borderTopRightRadius = -1;
    _borderTopStartRadius = -1;
    _borderTopEndRadius = -1;
    _borderBottomLeftRadius = -1;
    _borderBottomRightRadius = -1;
    _borderBottomStartRadius = -1;
    _borderBottomEndRadius = -1;
    _borderStyle = RCTBorderStyleSolid;
    self.clipsToBounds = NO;
  }

  return self;
}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:unused)

- (void)setReactLayoutDirection:(NSUserInterfaceLayoutDirection)layoutDirection
{
  if (_reactLayoutDirection != layoutDirection) {
    _reactLayoutDirection = layoutDirection;
    [self.layer setNeedsDisplay];
  }

//  if ([self respondsToSelector:@selector(setSemanticContentAttribute:)]) {
//    self.semanticContentAttribute =
//      layoutDirection == UIUserInterfaceLayoutDirectionLeftToRight ?
//        UISemanticContentAttributeForceLeftToRight :
//        UISemanticContentAttributeForceRightToLeft;
//  }
}

- (NSString *)accessibilityLabel
{
  NSString *label = super.accessibilityLabel;
  if (label) {
    return label;
  }
  return RCTRecursiveAccessibilityLabel(self);
}

- (BOOL)isFlipped
{
  return YES;
}

-(void) drawRect:(__unused NSRect)dirtyRect {}

- (BOOL)wantsDefaultClipping
{
  return self.clipsToBounds;
}

- (void)setPointerEvents:(RCTPointerEvents)pointerEvents
{
   NSLog(@" setPointerEvents is not implemented");
  _pointerEvents = pointerEvents;

//  self.userInteractionEnabled = (pointerEvents != RCTPointerEventsNone);
//  if (pointerEvents == RCTPointerEventsBoxNone) {
//    self.accessibilityViewIsModal = NO;
//  }
}

- (void)setTransform:(CATransform3D)transform
{
  _transform = transform;
}

- (NSView *)hitTest:(CGPoint)point
{
  // TODO: implement pointerEvents
//  switch (_pointerEvents) {
//    case RCTPointerEventsNone:
//      return nil;
//    case RCTPointerEventsUnspecified:
//      return RCTViewHitTest(self, point, event) ?: [super hitTest:point withEvent:event];
//    case RCTPointerEventsBoxOnly:
//      return [super hitTest:point withEvent:event] ? self: nil;
//    case RCTPointerEventsBoxNone:
//      return RCTViewHitTest(self, point, event);
//    default:
//      RCTLogError(@"Invalid pointer-events specified %zd on %@", _pointerEvents, self);
//      return [super hitTest:point withEvent:event];
//  }
  return [super hitTest:point];
}

- (NSView *)reactAccessibilityElement
{
  return self;
}

- (BOOL)isAccessibilityElement
{
  if (self.reactAccessibilityElement == self) {
    return [super isAccessibilityElement];
  }

  return NO;
}

- (BOOL)accessibilityActivate
{
  if (_onAccessibilityTap) {
    _onAccessibilityTap(nil);
    return YES;
  } else {
    return NO;
  }
}

- (BOOL)accessibilityPerformMagicTap
{
  if (_onMagicTap) {
    _onMagicTap(nil);
    return YES;
  } else {
    return NO;
  }
}

- (NSString *)description
{
  NSString *superDescription = super.description;
  NSRange semicolonRange = [superDescription rangeOfString:@";"];
  NSString *replacement = [NSString stringWithFormat:@"; reactTag: %@;", self.reactTag];
  
  if ([superDescription length] > 0 && semicolonRange.length > 0) {
    return [superDescription stringByReplacingCharactersInRange:semicolonRange withString:replacement];
  }
  return [NSString stringWithFormat:@"reactTag: %@;", self.reactTag];
}

#pragma mark - Statics for dealing with layoutGuides

+ (void)autoAdjustInsetsForView:(NSView<RCTAutoInsetsProtocol> *)parentView
                 withScrollView:(NSScrollView *)scrollView
                   updateOffset:(BOOL)updateOffset
{
  NSEdgeInsets baseInset = parentView.contentInset;
  CGFloat previousInsetTop = scrollView.contentInsets.top;
  //CGPoint contentOffset = scrollView.contentOffset;

  if (parentView.automaticallyAdjustContentInsets) {
    NSEdgeInsets autoInset = [self contentInsetsForView:parentView];
    baseInset.top += autoInset.top;
    baseInset.bottom += autoInset.bottom;
    baseInset.left += autoInset.left;
    baseInset.right += autoInset.right;
  }
  scrollView.contentInsets = baseInset;
  //scrollView.scrollIndicatorInsets = baseInset;

  if (updateOffset) {
    // If we're adjusting the top inset, then let's also adjust the contentOffset so that the view
    // elements above the top guide do not cover the content.
    // This is generally only needed when your views are initially laid out, for
    // manual changes to contentOffset, you can optionally disable this step
    CGFloat currentInsetTop = scrollView.contentInsets.top;
    if (currentInsetTop != previousInsetTop) {
      //contentOffset.y -= (currentInsetTop - previousInsetTop);
      //scrollView.contentOffset = contentOffset;
    }
  }
}

+ (NSEdgeInsets)contentInsetsForView:(__unused NSView *)view
{
  NSLog(@"contentInsetsForView not implemented");
//  while (view) {
//    NSViewController *controller = view.reactViewController;
//    if (controller) {
//      return (NSEdgeInsets){
//        controller.topLayoutGuide.length, 0,
//        controller.bottomLayoutGuide.length, 0
//      };
//    }
//    view = view.superview;
//  }
  return NSEdgeInsetsZero;
}

#pragma mark - View unmounting

- (void)react_remountAllSubviews
{
  if (_removeClippedSubviews) {
    for (NSView *view in self.reactSubviews) {
      if (view.superview != self) {
        [self addSubview:view];
        [view react_remountAllSubviews];
      }
    }
  } else {
    // If _removeClippedSubviews is false, we must already be showing all subviews
    [super react_remountAllSubviews];
  }
}

- (void)react_updateClippedSubviewsWithClipRect:(CGRect)clipRect relativeToView:(NSView *)clipView
{
  // TODO (#5906496): for scrollviews (the primary use-case) we could
  // optimize this by only doing a range check along the scroll axis,
  // instead of comparing the whole frame

  if (!_removeClippedSubviews) {
    // Use default behavior if unmounting is disabled
    return [super react_updateClippedSubviewsWithClipRect:clipRect relativeToView:clipView];
  }

  if (self.reactSubviews.count == 0) {
    // Do nothing if we have no subviews
    return;
  }

  if (CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {
    // Do nothing if layout hasn't happened yet
    return;
  }

  // Convert clipping rect to local coordinates
  clipRect = [clipView convertRect:clipRect toView:self];
  clipRect = CGRectIntersection(clipRect, self.bounds);
  clipView = self;

  // Mount / unmount views
  for (NSView *view in self.reactSubviews) {
    if (!CGSizeEqualToSize(CGRectIntersection(clipRect, view.frame).size, CGSizeZero)) {
      // View is at least partially visible, so remount it if unmounted
      [self addSubview:view];

      // Then test its subviews
      if (CGRectContainsRect(clipRect, view.frame)) {
        // View is fully visible, so remount all subviews
        [view react_remountAllSubviews];
      } else {
        // View is partially visible, so update clipped subviews
        [view react_updateClippedSubviewsWithClipRect:clipRect relativeToView:clipView];
      }

    } else if (view.superview) {

      // View is completely outside the clipRect, so unmount it
      [view removeFromSuperview];
    }
  }
}

- (void)setRemoveClippedSubviews:(BOOL)removeClippedSubviews
{
  if (!removeClippedSubviews && _removeClippedSubviews) {
    [self react_remountAllSubviews];
  }
  _removeClippedSubviews = removeClippedSubviews;
}

- (void)didUpdateReactSubviews
{
  if (_removeClippedSubviews) {
    [self updateClippedSubviews];
  } else {
    [super didUpdateReactSubviews];
  }
}

- (void)updateClippedSubviews
{
  // Find a suitable view to use for clipping
  NSView *clipView = [self react_findClipView];
  if (clipView) {
    [self react_updateClippedSubviewsWithClipRect:clipView.bounds relativeToView:clipView];
  }
}

- (void)layout
{
  // TODO (#5906496): this a nasty performance drain, but necessary
  // to prevent gaps appearing when the loading spinner disappears.
  // We might be able to fix this another way by triggering a call
  // to updateClippedSubviews manually after loading

  [super layout];

  if (_removeClippedSubviews) {
    [self updateClippedSubviews];
  }

}

#pragma mark - Borders

- (NSColor *)backgroundColor
{
  return _backgroundColor;
}

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
  if ([_backgroundColor isEqual:backgroundColor]) {
    return;
  }
  if (backgroundColor == nil) {
    [self setWantsLayer:NO];
    self.layer = NULL;
    return;
  }
  if (![self wantsLayer] || self.layer == nil) {
    [self setWantsLayer:YES];
    self.layer.delegate = self;
  }
  [self.layer setBackgroundColor:[backgroundColor CGColor]];
  [self.layer setNeedsDisplay];
  [self setNeedsDisplay:YES];
  _backgroundColor = backgroundColor;
}

static CGFloat RCTDefaultIfNegativeTo(CGFloat defaultValue, CGFloat x) {
  return x >= 0 ? x : defaultValue;
};

- (NSEdgeInsets)bordersAsInsets
{
  const CGFloat borderWidth = MAX(0, _borderWidth);
  const BOOL isRTL = _reactLayoutDirection == NSUserInterfaceLayoutDirectionRightToLeft;

  if ([[RCTI18nUtil sharedInstance] doLeftAndRightSwapInRTL]) {
    const CGFloat borderStartWidth = RCTDefaultIfNegativeTo(_borderLeftWidth, _borderStartWidth);
    const CGFloat borderEndWidth = RCTDefaultIfNegativeTo(_borderRightWidth, _borderEndWidth);

    const CGFloat directionAwareBorderLeftWidth = isRTL ? borderEndWidth : borderStartWidth;
    const CGFloat directionAwareBorderRightWidth = isRTL ? borderStartWidth : borderEndWidth;

    return (NSEdgeInsets) {
      RCTDefaultIfNegativeTo(borderWidth, _borderTopWidth),
      RCTDefaultIfNegativeTo(borderWidth, directionAwareBorderLeftWidth),
      RCTDefaultIfNegativeTo(borderWidth, _borderBottomWidth),
      RCTDefaultIfNegativeTo(borderWidth, directionAwareBorderRightWidth),
    };
  }

  const CGFloat directionAwareBorderLeftWidth = isRTL ? _borderEndWidth : _borderStartWidth;
  const CGFloat directionAwareBorderRightWidth = isRTL ? _borderStartWidth : _borderEndWidth;

  return (NSEdgeInsets) {
    RCTDefaultIfNegativeTo(borderWidth, _borderTopWidth),
    RCTDefaultIfNegativeTo(borderWidth, RCTDefaultIfNegativeTo(_borderLeftWidth, directionAwareBorderLeftWidth)),
    RCTDefaultIfNegativeTo(borderWidth, _borderBottomWidth),
    RCTDefaultIfNegativeTo(borderWidth, RCTDefaultIfNegativeTo(_borderRightWidth, directionAwareBorderRightWidth)),
  };
}

- (RCTCornerRadii)cornerRadii
{
  const BOOL isRTL = _reactLayoutDirection == NSUserInterfaceLayoutDirectionRightToLeft;
  const CGFloat radius = MAX(0, _borderRadius);

  CGFloat topLeftRadius;
  CGFloat topRightRadius;
  CGFloat bottomLeftRadius;
  CGFloat bottomRightRadius;

  if ([[RCTI18nUtil sharedInstance] doLeftAndRightSwapInRTL]) {
    const CGFloat topStartRadius = RCTDefaultIfNegativeTo(_borderTopLeftRadius, _borderTopStartRadius);
    const CGFloat topEndRadius = RCTDefaultIfNegativeTo(_borderTopRightRadius, _borderTopEndRadius);
    const CGFloat bottomStartRadius = RCTDefaultIfNegativeTo(_borderBottomLeftRadius, _borderBottomStartRadius);
    const CGFloat bottomEndRadius = RCTDefaultIfNegativeTo(_borderBottomRightRadius, _borderBottomEndRadius);

    const CGFloat directionAwareTopLeftRadius = isRTL ? topEndRadius : topStartRadius;
    const CGFloat directionAwareTopRightRadius = isRTL ? topStartRadius : topEndRadius;
    const CGFloat directionAwareBottomLeftRadius = isRTL ? bottomEndRadius : bottomStartRadius;
    const CGFloat directionAwareBottomRightRadius = isRTL ? bottomStartRadius : bottomEndRadius;

    topLeftRadius = RCTDefaultIfNegativeTo(radius, directionAwareTopLeftRadius);
    topRightRadius = RCTDefaultIfNegativeTo(radius, directionAwareTopRightRadius);
    bottomLeftRadius = RCTDefaultIfNegativeTo(radius, directionAwareBottomLeftRadius);
    bottomRightRadius = RCTDefaultIfNegativeTo(radius, directionAwareBottomRightRadius);
  } else {
    const CGFloat directionAwareTopLeftRadius = isRTL ? _borderTopEndRadius : _borderTopStartRadius;
    const CGFloat directionAwareTopRightRadius = isRTL ? _borderTopStartRadius : _borderTopEndRadius;
    const CGFloat directionAwareBottomLeftRadius = isRTL ? _borderBottomEndRadius : _borderBottomStartRadius;
    const CGFloat directionAwareBottomRightRadius = isRTL ? _borderBottomStartRadius : _borderBottomEndRadius;

    topLeftRadius = RCTDefaultIfNegativeTo(radius, RCTDefaultIfNegativeTo(_borderTopLeftRadius, directionAwareTopLeftRadius));
    topRightRadius = RCTDefaultIfNegativeTo(radius, RCTDefaultIfNegativeTo(_borderTopRightRadius, directionAwareTopRightRadius));
    bottomLeftRadius = RCTDefaultIfNegativeTo(radius, RCTDefaultIfNegativeTo(_borderBottomLeftRadius, directionAwareBottomLeftRadius));
    bottomRightRadius = RCTDefaultIfNegativeTo(radius, RCTDefaultIfNegativeTo(_borderBottomRightRadius, directionAwareBottomRightRadius));
  }

  // Get scale factors required to prevent radii from overlapping
  const CGSize size = self.bounds.size;
  const CGFloat topScaleFactor = RCTZeroIfNaN(MIN(1, size.width / (topLeftRadius + topRightRadius)));
  const CGFloat bottomScaleFactor = RCTZeroIfNaN(MIN(1, size.width / (bottomLeftRadius + bottomRightRadius)));
  const CGFloat rightScaleFactor = RCTZeroIfNaN(MIN(1, size.height / (topRightRadius + bottomRightRadius)));
  const CGFloat leftScaleFactor = RCTZeroIfNaN(MIN(1, size.height / (topLeftRadius + bottomLeftRadius)));

  // Return scaled radii
  return (RCTCornerRadii){
    topLeftRadius * MIN(topScaleFactor, leftScaleFactor),
    topRightRadius * MIN(topScaleFactor, rightScaleFactor),
    bottomLeftRadius * MIN(bottomScaleFactor, leftScaleFactor),
    bottomRightRadius * MIN(bottomScaleFactor, rightScaleFactor),
  };
}

- (RCTBorderColors)borderColors
{
  const BOOL isRTL = _reactLayoutDirection == NSUserInterfaceLayoutDirectionRightToLeft;

  if ([[RCTI18nUtil sharedInstance] doLeftAndRightSwapInRTL]) {
    const CGColorRef borderStartColor = _borderStartColor ?: _borderLeftColor;
    const CGColorRef borderEndColor = _borderEndColor ?: _borderRightColor;

    const CGColorRef directionAwareBorderLeftColor = isRTL ? borderEndColor : borderStartColor;
    const CGColorRef directionAwareBorderRightColor = isRTL ? borderStartColor : borderEndColor;

    return (RCTBorderColors){
      _borderTopColor ?: _borderColor,
      directionAwareBorderLeftColor ?: _borderColor,
      _borderBottomColor ?: _borderColor,
      directionAwareBorderRightColor ?: _borderColor,
    };
  }

  const CGColorRef directionAwareBorderLeftColor = isRTL ? _borderEndColor : _borderStartColor;
  const CGColorRef directionAwareBorderRightColor = isRTL ? _borderStartColor : _borderEndColor;

  return (RCTBorderColors){
    _borderTopColor ?: _borderColor,
    directionAwareBorderLeftColor ?: _borderLeftColor ?: _borderColor,
    _borderBottomColor ?: _borderColor,
    directionAwareBorderRightColor ?: _borderRightColor ?: _borderColor,
  };
}

- (void)reactSetFrame:(CGRect)frame
{
  // TODO: understand if we need to be able to disable live resizing for certain use
  //  if (self.inLiveResize && !self.respondsToLiveResizing) {
  //    return;
  //  }
  // If frame is zero, or below the threshold where the border radii can
  // be rendered as a stretchable image, we'll need to re-render.
  // TODO: detect up-front if re-rendering is necessary
  CGSize oldSize = self.bounds.size;
  [super reactSetFrame:frame];
  if (!CGSizeEqualToSize(self.bounds.size, oldSize)) {
    [self.layer setNeedsDisplay];
  }
}

- (void)displayLayer:(CALayer *)layer
{
  if (self.shouldBeTransformed) {
    self.layer.transform = self.transform;
    self.shouldBeTransformed = NO;
  }
  
  if (CGSizeEqualToSize(layer.bounds.size, CGSizeZero)) {
    return;
  }

  RCTUpdateShadowPathForView(self);

  const RCTCornerRadii cornerRadii = [self cornerRadii];
  const NSEdgeInsets borderInsets = [self bordersAsInsets];
  const RCTBorderColors borderColors = [self borderColors];

  BOOL useIOSBorderRendering =
  !RCTRunningInTestEnvironment() &&
  RCTCornerRadiiAreEqual(cornerRadii) &&
  RCTBorderInsetsAreEqual(borderInsets) &&
  RCTBorderColorsAreEqual(borderColors) &&
  _borderStyle == RCTBorderStyleSolid &&

  // iOS draws borders in front of the content whereas CSS draws them behind
  // the content. For this reason, only use iOS border drawing when clipping
  // or when the border is hidden.

  (borderInsets.top == 0 || (borderColors.top && CGColorGetAlpha(borderColors.top) == 0) || self.clipsToBounds);

  // iOS clips to the outside of the border, but CSS clips to the inside. To
  // solve this, we'll need to add a container view inside the main view to
  // correctly clip the subviews.
  if (useIOSBorderRendering) {
    layer.cornerRadius = cornerRadii.topLeft;
    layer.borderColor = borderColors.left;
    layer.borderWidth = borderInsets.left;
    layer.contents = nil;
    layer.needsDisplayOnBoundsChange = NO;
    layer.mask = nil;
    return;
  }

  NSImage *image = RCTGetBorderImage(_borderStyle,
                                     layer.bounds.size,
                                     cornerRadii,
                                     borderInsets,
                                     borderColors,
                                     _backgroundColor.CGColor,
                                     self.clipsToBounds);

  layer.backgroundColor = NULL;

  if (image == nil) {
    layer.contents = nil;
    layer.needsDisplayOnBoundsChange = NO;
    return;
  }

  CGRect contentsCenter = ({
    CGSize size = image.size;
    NSEdgeInsets insets = image.capInsets;
    CGRectMake(
      insets.left / size.width,
      insets.top / size.height,
      1.0 / size.width,
      1.0 / size.height
    );
  });

  if (RCTRunningInTestEnvironment()) {
    const CGSize size = self.bounds.size;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [image drawInRect:(CGRect){CGPointZero, size}];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    contentsCenter = CGRectMake(0, 0, 1, 1);
  }

  layer.contents = (id)image;
  layer.contentsScale = [image recommendedLayerContentsScale:0.0];
  layer.contentsCenter = contentsCenter;
  layer.magnificationFilter = kCAFilterNearest;
  layer.needsDisplayOnBoundsChange = YES;

  [self updateClippingForLayer:layer];
}

static BOOL RCTLayerHasShadow(CALayer *layer)
{
  return layer.shadowOpacity * CGColorGetAlpha(layer.shadowColor) > 0;
}

static void RCTUpdateShadowPathForView(RCTView *view)
{
  if (RCTLayerHasShadow(view.layer)) {
    if (CGColorGetAlpha(view.backgroundColor.CGColor) > 0.999) {

      // If view has a solid background color, calculate shadow path from border
      const RCTCornerRadii cornerRadii = [view cornerRadii];
      const RCTCornerInsets cornerInsets = RCTGetCornerInsets(cornerRadii, NSEdgeInsetsZero);
      CGPathRef shadowPath = RCTPathCreateWithRoundedRect(view.bounds, cornerInsets, NULL);
      view.layer.shadowPath = shadowPath;
      CGPathRelease(shadowPath);

    } else {

      // Can't accurately calculate box shadow, so fall back to pixel-based shadow
      view.layer.shadowPath = nil;

      RCTLogAdvice(@"View #%@ of type %@ has a shadow set but cannot calculate "
        "shadow efficiently. Consider setting a background color to "
        "fix this, or apply the shadow to a more specific component.",
        view.reactTag, [view class]);
    }
  }
}

- (void)updateClippingForLayer:(CALayer *)layer
{
  CALayer *mask = nil;
  CGFloat cornerRadius = 0;
  if (self.clipsToBounds) {

    const RCTCornerRadii cornerRadii = [self cornerRadii];
    if (RCTCornerRadiiAreEqual(cornerRadii)) {
      cornerRadius = cornerRadii.topLeft;
    } else {
      CAShapeLayer *shapeLayer = [CAShapeLayer layer];
      CGPathRef path = RCTPathCreateWithRoundedRect(self.bounds, RCTGetCornerInsets(cornerRadii, NSEdgeInsetsZero), NULL);
      shapeLayer.path = path;
      CGPathRelease(path);
      mask = shapeLayer;
    }
  }
  layer.cornerRadius = cornerRadius;
  layer.mask = mask;
}

- (void)contextMenuItemClicked:(NSMenuItem *)sender
{
  NSDictionary *menuItem = (NSDictionary *)sender.representedObject;
  if (_onContextMenuItemClick) {
    _onContextMenuItemClick(@{@"menuItem": menuItem});
  } else {
    RCTLogWarn(@"Set onContextMenuItemClick to handle this event");
  }
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
  NSPasteboard *pboard;
  NSDragOperation sourceDragMask;
  sourceDragMask = [sender draggingSourceOperationMask];
  pboard = [sender draggingPasteboard];

  _onDragEnter(@{
                 @"sourceDragMask": @(sourceDragMask),
                 });
  if ( [[pboard types] containsObject:NSColorPboardType] ) {
    if (sourceDragMask & NSDragOperationGeneric) {
      return NSDragOperationGeneric;
    }
  }
  if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
    if (sourceDragMask & NSDragOperationLink) {
      return NSDragOperationLink;
    } else if (sourceDragMask & NSDragOperationCopy) {
      return NSDragOperationCopy;
    }
  }
  return NSDragOperationNone;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
  _onDragLeave(@{@"sourceDragMask": @([sender draggingSourceOperationMask])});
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
  NSPasteboard *pboard = [sender draggingPasteboard];

  if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
    NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
    _onDrop(@{@"files": files });
  }
  return YES;
}

#pragma mark Border Color

#define setBorderColor(side)                                \
  - (void)setBorder##side##Color:(CGColorRef)color          \
  {                                                         \
    if (CGColorEqualToColor(_border##side##Color, color)) { \
      return;                                               \
    }                                                       \
    CGColorRelease(_border##side##Color);                   \
    _border##side##Color = CGColorRetain(color);            \
    [self.layer setNeedsDisplay];                           \
  }

setBorderColor()
setBorderColor(Top)
setBorderColor(Right)
setBorderColor(Bottom)
setBorderColor(Left)
setBorderColor(Start)
setBorderColor(End)

#pragma mark - Border Width

#define setBorderWidth(side)                    \
  - (void)setBorder##side##Width:(CGFloat)width \
  {                                             \
    if (_border##side##Width == width) {        \
      return;                                   \
    }                                           \
    _border##side##Width = width;               \
    [self.layer setNeedsDisplay];               \
  }

setBorderWidth()
setBorderWidth(Top)
setBorderWidth(Right)
setBorderWidth(Bottom)
setBorderWidth(Left)
setBorderWidth(Start)
setBorderWidth(End)

#pragma mark - Border Radius

#define setBorderRadius(side)                     \
  - (void)setBorder##side##Radius:(CGFloat)radius \
  {                                               \
    if (_border##side##Radius == radius) {        \
      return;                                     \
    }                                             \
    _border##side##Radius = radius;               \
    [self.layer setNeedsDisplay];                 \
  }

setBorderRadius()
setBorderRadius(TopLeft)
setBorderRadius(TopRight)
setBorderRadius(TopStart)
setBorderRadius(TopEnd)
setBorderRadius(BottomLeft)
setBorderRadius(BottomRight)
setBorderRadius(BottomStart)
setBorderRadius(BottomEnd)

#pragma mark - Border Style

#define setBorderStyle(side)                           \
  - (void)setBorder##side##Style:(RCTBorderStyle)style \
  {                                                    \
    if (_border##side##Style == style) {               \
      return;                                          \
    }                                                  \
    _border##side##Style = style;                      \
    [self.layer setNeedsDisplay];                      \
  }

setBorderStyle()

- (void)dealloc
{
  CGColorRelease(_borderColor);
  CGColorRelease(_borderTopColor);
  CGColorRelease(_borderRightColor);
  CGColorRelease(_borderBottomColor);
  CGColorRelease(_borderLeftColor);
  CGColorRelease(_borderStartColor);
  CGColorRelease(_borderEndColor);
}

@end
