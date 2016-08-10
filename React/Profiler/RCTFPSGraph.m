/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTFPSGraph.h"
#import "QuartzCore/CAShapeLayer.h"
#import "RCTAssert.h"

#if RCT_DEV

@interface RCTFPSGraph()

@property (nonatomic, strong, readonly) CAShapeLayer *graph;
@property (nonatomic, strong, readonly) NSTextField *label;

@end

@implementation RCTFPSGraph
{
  CAShapeLayer *_graph;
  NSTextField *_label;

  CGFloat *_frames;
  NSColor *_color;

  NSTimeInterval _prevTime;
  NSUInteger _frameCount;
  NSUInteger _FPS;
  NSUInteger _maxFPS;
  NSUInteger _minFPS;
  NSUInteger _length;
  NSUInteger _height;
}

- (instancetype)initWithFrame:(CGRect)frame color:(NSColor *)color
{
  if ((self = [super initWithFrame:frame])) {
    _frameCount = -1;
    _prevTime = -1;
    _maxFPS = 0;
    _minFPS = 60;
    _length = (NSUInteger)floor(frame.size.width);
    _height = (NSUInteger)floor(frame.size.height);
    _frames = calloc(sizeof(CGFloat), _length);
    _color = color;

    [self setWantsLayer:YES];
    [self.layer addSublayer:self.graph];
    [self addSubview:self.label];
  }
  return self;
}

- (void)dealloc
{
  free(_frames);
}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithFrame:(CGRect)frame)
RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:(NSCoder *)aDecoder)

- (CAShapeLayer *)graph
{
  if (!_graph) {
    _graph = [CAShapeLayer new];
    _graph.frame = self.bounds;
    _graph.backgroundColor = [_color colorWithAlphaComponent:0.2].CGColor;
    _graph.fillColor = _color.CGColor;
  }

  return _graph;
}

- (NSTextField *)label
{
  if (!_label) {
    _label = [[NSTextField alloc] initWithFrame:self.bounds];
    _label.font = [NSFont boldSystemFontOfSize:13];
    _label.alignment = NSTextAlignmentCenter;
    _label.bezeled = NO;
    _label.drawsBackground = NO;
    _label.editable = NO;

  }

  return _label;
}

- (void)onTick:(NSTimeInterval)timestamp
{
  _frameCount++;
  if (_prevTime == -1) {
    _prevTime = timestamp;
  } else if (timestamp - _prevTime >= 1) {
    _FPS = round(_frameCount / (timestamp - _prevTime));
    _minFPS = MIN(_minFPS, _FPS);
    _maxFPS = MAX(_maxFPS, _FPS);

    dispatch_async(dispatch_get_main_queue(), ^{
      self->_label.stringValue = [NSString stringWithFormat:@"%lu", (unsigned long)self->_FPS];
    });


    CGFloat scale = 60.0 / _height;
    for (NSUInteger i = 0; i < _length - 1; i++) {
      _frames[i] = _frames[i + 1];
    }
    _frames[_length - 1] = _FPS / scale;

    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 0, 0);
    for (NSUInteger i = 0; i < _length; i++) {
      CGPathAddLineToPoint(path, NULL, i, _frames[i]);
    }
    CGPathAddLineToPoint(path, NULL, _length - 1, 0);

    _graph.path = path;
    CGPathRelease(path);

    _prevTime = timestamp;
    _frameCount = 0;
  }
}

@end

#endif
