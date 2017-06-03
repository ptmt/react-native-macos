/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTText.h"

#import <QuartzCore/QuartzCore.h>
// #import <MobileCoreServices/UTCoreTypes.h>

#import <React/RCTUtils.h>
#import <React/NSView+React.h>

#import "RCTShadowText.h"

// https://github.com/BigZaphod/Chameleon/blob/84605ede274bd82b330d72dd6ac41e64eb925fd7/UIKit/Classes/UIGeometry.h
CGRect UIEdgeInsetsInsetRect(CGRect rect, NSEdgeInsets insets) {
  rect.origin.x    += insets.left;
  rect.origin.y    += insets.top;
  rect.size.width  -= (insets.left + insets.right);
  rect.size.height -= (insets.top  + insets.bottom);
  return rect;
}

@implementation NSBezierPath (BezierPathQuartzUtilities)
// This method works only in OS X v10.2 and later.
- (CGPathRef)quartzPath
{
  long i, numElements;

  // Need to begin a path here.
  CGPathRef           immutablePath = NULL;

  // Then draw the path elements.
  numElements = [self elementCount];
  if (numElements > 0)
  {
    CGMutablePathRef    path = CGPathCreateMutable();
    NSPoint             points[3];
    BOOL                didClosePath = YES;

    for (i = 0; i < numElements; i++)
    {
      switch ([self elementAtIndex:i associatedPoints:points])
      {
        case NSMoveToBezierPathElement:
          CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
          break;

        case NSLineToBezierPathElement:
          CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
          didClosePath = NO;
          break;

        case NSCurveToBezierPathElement:
          CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
                                points[1].x, points[1].y,
                                points[2].x, points[2].y);
          didClosePath = NO;
          break;

        case NSClosePathBezierPathElement:
          CGPathCloseSubpath(path);
          didClosePath = YES;
          break;
      }
    }

    // Be sure the path is closed or Quartz may not do valid hit detection.
    if (!didClosePath)
      CGPathCloseSubpath(path);

    immutablePath = CGPathCreateCopy(path);
    CGPathRelease(path);
  }

  return immutablePath; // TODO: potential leak
}
@end

static void collectNonTextDescendants(RCTText *view, NSMutableArray *nonTextDescendants)
{
  for (NSView *child in view.reactSubviews) {
    if ([child isKindOfClass:[RCTText class]]) {
      collectNonTextDescendants((RCTText *)child, nonTextDescendants);
    } else if (!CGRectEqualToRect(child.frame, CGRectZero)) {
      [nonTextDescendants addObject:child];
    }
  }
}

@implementation RCTText
{
  NSTextStorage *_textStorage;
  CAShapeLayer *_highlightLayer;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    _textStorage = [NSTextStorage new];
  }
  return self;
}

- (BOOL)isFlipped
{
  return YES;
}

- (NSString *)description
{
  NSString *superDescription = super.description;
  NSRange semicolonRange = [superDescription rangeOfString:@";"];
  NSString *replacement = [NSString stringWithFormat:@"; reactTag: %@; text: %@", self.reactTag, self.textStorage.string];
  return [superDescription stringByReplacingCharactersInRange:semicolonRange withString:replacement];
}

- (void)setSelectable:(BOOL)selectable
{
  if (_selectable == selectable) {
    return;
  }

  _selectable = selectable;

  if (_selectable) {
    [self enableContextMenu];
  }
  else {
    [self disableContextMenu];
  }
}

- (void)reactSetFrame:(CGRect)frame
{
  [super reactSetFrame:frame];
}

- (void)reactSetInheritedBackgroundColor:(NSColor *)inheritedBackgroundColor
{
  if (self.wantsLayer == NO) {
    self.wantsLayer = YES;
    self.layer = [[CALayer alloc] init];
  }
  self.layer.backgroundColor = [inheritedBackgroundColor CGColor];
}

- (void)didUpdateReactSubviews
{
  // Do nothing, as subviews are managed by `setTextStorage:` method
}

- (void)setTextStorage:(NSTextStorage *)textStorage
{
  if (_textStorage != textStorage) {
    _textStorage = textStorage;

    // Update subviews
    NSMutableArray *nonTextDescendants = [NSMutableArray new];
    collectNonTextDescendants(self, nonTextDescendants);
    NSArray *subviews = self.subviews;
    if (![subviews isEqualToArray:nonTextDescendants]) {
      for (NSView *child in subviews) {
        if (![nonTextDescendants containsObject:child]) {
          [child removeFromSuperview];
        }
      }
      for (NSView *child in nonTextDescendants) {
        [self addSubview:child];
      }
    }

    [self setNeedsDisplay:YES];
  }
}

- (void)drawRect:(CGRect)dirtyRect
{
  NSLayoutManager *layoutManager = [_textStorage.layoutManagers firstObject];
  NSTextContainer *textContainer = [layoutManager.textContainers firstObject];

  NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
  CGRect textFrame = self.textFrame;
  [layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:textFrame.origin];
  [layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:textFrame.origin];

  __block NSBezierPath *highlightPath = nil;
  NSRange characterRange = [layoutManager characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];

  [layoutManager.textStorage enumerateAttribute:RCTIsHighlightedAttributeName inRange:characterRange options:0 usingBlock:^(NSNumber *value, NSRange range, BOOL *_) {
    if (!value.boolValue) {
      return;
    }

    [layoutManager enumerateEnclosingRectsForGlyphRange:range withinSelectedGlyphRange:range inTextContainer:textContainer usingBlock:^(CGRect enclosingRect, __unused BOOL *__) {
      NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:CGRectInset(enclosingRect, -2, -2) xRadius:2 yRadius:2];
      if (highlightPath) {
        [highlightPath appendBezierPath:path];
      } else {
        highlightPath = path;
      }
    }];
  }];

  if (highlightPath) {
    if (!_highlightLayer) {
      _highlightLayer = [CAShapeLayer layer];
      _highlightLayer.fillColor = [NSColor colorWithWhite:0 alpha:0.25].CGColor;
      [self.layer addSublayer:_highlightLayer];
    }
    _highlightLayer.position = (CGPoint){_contentInset.left, _contentInset.top};
    _highlightLayer.path = highlightPath.quartzPath;
  } else {
    [_highlightLayer removeFromSuperlayer];
    _highlightLayer = nil;
  }
}

- (NSNumber *)reactTagAtPoint:(CGPoint)point
{
  NSNumber *reactTag = self.reactTag;

  CGFloat fraction;
  NSLayoutManager *layoutManager = _textStorage.layoutManagers.firstObject;
  NSTextContainer *textContainer = layoutManager.textContainers.firstObject;
  NSUInteger characterIndex = [layoutManager characterIndexForPoint:point
                                                    inTextContainer:textContainer
                           fractionOfDistanceBetweenInsertionPoints:&fraction];

  // If the point is not before (fraction == 0.0) the first character and not
  // after (fraction == 1.0) the last character, then the attribute is valid.
  if (_textStorage.length > 0 && (fraction > 0 || characterIndex > 0) && (fraction < 1 || characterIndex < _textStorage.length - 1)) {
    reactTag = [_textStorage attribute:RCTReactTagAttributeName atIndex:characterIndex effectiveRange:NULL];
  }
  return reactTag;
}

- (void)viewDidMoveToWindow
{
  [super viewDidMoveToWindow];

  if (!self.window) {
    self.layer.contents = nil;
    if (_highlightLayer) {
      [_highlightLayer removeFromSuperlayer];
      _highlightLayer = nil;
    }
  } else if (_textStorage.length) {
    [self setNeedsDisplay:YES];
  }
}


#pragma mark - Accessibility

- (NSString *)accessibilityLabel
{
  return _textStorage.string;
}

#pragma mark - Context Menu

- (void)enableContextMenu
{

}

- (void)disableContextMenu
{
}

- (BOOL)canBecomeFirstResponder
{
  return _selectable;
}

//- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
//{
//  if (_selectable && action == @selector(copy:)) {
//    return YES;
//  }
//
//  return [self.nextResponder canPerformAction:action withSender:sender];
//}

- (void)copy:(id)sender
{
#if !TARGET_OS_TV
  #endif
}

@end
