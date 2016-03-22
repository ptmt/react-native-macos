//
//  Taken from https://github.com/BigZaphod/Chameleon/blob/master/UIKit/Classes/UIViewAnimationGroup.m

#import "NSView+NSViewAnimationWithBlocks.h"
#import <QuartzCore/QuartzCore.h>

static NSMutableSet *runningAnimationGroups = nil;

static CAMediaTimingFunction *CAMediaTimingFunctionFromNSViewAnimationCurve(NSViewAnimationCurve curve)
{
  switch (curve) {
    case NSViewAnimationCurveEaseInOut:	return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    case NSViewAnimationCurveEaseIn:	return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    case NSViewAnimationCurveEaseOut:	return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    case NSViewAnimationCurveLinear:	return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
  }
  return nil;
}


BOOL NSViewAnimationOptionIsSet(NSViewAnimationOptions options, NSViewAnimationOptions option)
{
  return ((options & option) == option);
}

static inline NSViewAnimationOptions NSViewAnimationOptionCurve(NSViewAnimationOptions options)
{
  return (options & (NSViewAnimationOptionCurveEaseInOut
                     | NSViewAnimationOptionCurveEaseIn
                     | NSViewAnimationOptionCurveEaseOut
                     | NSViewAnimationOptionCurveLinear));
}


static inline NSViewAnimationOptions NSViewAnimationOptionTransition(NSViewAnimationOptions options)
{
  return (options & (NSViewAnimationOptionTransitionNone
                     | NSViewAnimationOptionTransitionFlipFromLeft
                     | NSViewAnimationOptionTransitionFlipFromRight
                     | NSViewAnimationOptionTransitionCurlUp
                     | NSViewAnimationOptionTransitionCurlDown
                     | NSViewAnimationOptionTransitionCrossDissolve
                     | NSViewAnimationOptionTransitionFlipFromTop
                     | NSViewAnimationOptionTransitionFlipFromBottom));
}


@implementation NSViewAnimationGroup
{
  NSUInteger _waitingAnimations;
  BOOL _didStart;
  CFTimeInterval _animationBeginTime;
  NSView *_transitionView;
  BOOL _transitionShouldCache;
  NSMutableSet *_animatingViews;
}

- (id)initWithAnimationOptions:(NSViewAnimationOptions)options
{
  if ((self=[super init])) {
    _waitingAnimations = 1;
    _animationBeginTime = CACurrentMediaTime();
    _animatingViews = [NSMutableSet setWithCapacity:2];

    self.duration = 200;

    self.repeatCount = NSViewAnimationOptionIsSet(options, NSViewAnimationOptionRepeat)? FLT_MAX : 0;
    self.allowUserInteraction = NSViewAnimationOptionIsSet(options, NSViewAnimationOptionAllowUserInteraction);
    self.repeatAutoreverses = NSViewAnimationOptionIsSet(options, NSViewAnimationOptionAutoreverse);
    self.beginsFromCurrentState = NSViewAnimationOptionIsSet(options, NSViewAnimationOptionBeginFromCurrentState);

    const NSViewAnimationOptions animationCurve = NSViewAnimationOptionCurve(options);
    if (animationCurve == NSViewAnimationOptionCurveEaseIn) {
      self.curve = NSViewAnimationCurveEaseIn;
    } else if (animationCurve == NSViewAnimationOptionCurveEaseOut) {
      self.curve = NSViewAnimationCurveEaseOut;
    } else if (animationCurve == NSViewAnimationOptionCurveLinear) {
      self.curve = NSViewAnimationCurveLinear;
    } else {
      self.curve = NSViewAnimationCurveEaseInOut;
    }

    const NSViewAnimationOptions animationTransition = NSViewAnimationOptionTransition(options);
    if (animationTransition == NSViewAnimationOptionTransitionFlipFromLeft) {
      self.transition = NSViewAnimationGroupTransitionFlipFromLeft;
    } else if (animationTransition == NSViewAnimationOptionTransitionFlipFromRight) {
      self.transition = NSViewAnimationGroupTransitionFlipFromRight;
    } else if (animationTransition == NSViewAnimationOptionTransitionCurlUp) {
      self.transition = NSViewAnimationGroupTransitionCurlUp;
    } else if (animationTransition == NSViewAnimationOptionTransitionCurlDown) {
      self.transition = NSViewAnimationGroupTransitionCurlDown;
    } else if (animationTransition == NSViewAnimationOptionTransitionCrossDissolve) {
      self.transition = NSViewAnimationGroupTransitionCrossDissolve;
    } else if (animationTransition == NSViewAnimationOptionTransitionFlipFromTop) {
      self.transition = NSViewAnimationGroupTransitionFlipFromTop;
    } else if (animationTransition == NSViewAnimationOptionTransitionFlipFromBottom) {
      self.transition = NSViewAnimationGroupTransitionFlipFromBottom;
    } else {
      self.transition = NSViewAnimationGroupTransitionNone;
    }
  }
  return self;
}

- (void)notifyAnimationsDidStartIfNeeded
{
  if (!_didStart) {
    _didStart = YES;

    @synchronized(runningAnimationGroups) {
      [runningAnimationGroups addObject:self];
    }

    if ([self.delegate respondsToSelector:self.willStartSelector]) {
      typedef void(*WillStartMethod)(id, SEL, NSString *, void *);
      WillStartMethod method = (WillStartMethod)[self.delegate methodForSelector:self.willStartSelector];
      method(self.delegate, self.willStartSelector, self.name, self.context);
    }
  }
}

- (void)animationDidStart:(CAAnimation *)theAnimation
{
  NSAssert([NSThread isMainThread], @"expecting this to be on the main thread");

  [self notifyAnimationsDidStartIfNeeded];
}

- (void)notifyAnimationsDidStopIfNeededUsingStatus:(BOOL)animationsDidFinish
{
  if (_waitingAnimations == 0) {
    if ([self.delegate respondsToSelector:self.didStopSelector]) {
      NSNumber *finishedArgument = [NSNumber numberWithBool:animationsDidFinish];
      typedef void(*DidFinishMethod)(id, SEL, NSString *, NSNumber *, void *);
      DidFinishMethod method = (DidFinishMethod)[self.delegate methodForSelector:self.didStopSelector];
      method(self.delegate, self.didStopSelector, self.name, finishedArgument, self.context);
    }

    if (self.completionBlock) {
      self.completionBlock(animationsDidFinish);
    }

    @synchronized(runningAnimationGroups) {
      [_animatingViews removeAllObjects];
      [runningAnimationGroups removeObject:self];
    }
  }
}

- (void)setTransitionView:(NSView *)view shouldCache:(BOOL)cache
{
  _transitionView = view;
  _transitionShouldCache = cache;
}

- (void)animationDidStop:(__unused CAAnimation *)theAnimation finished:(BOOL)flag
{
  NSAssert([NSThread isMainThread], @"expecting this to be on the main thread");

  _waitingAnimations--;
  [self notifyAnimationsDidStopIfNeededUsingStatus:flag];}

- (CAAnimation *)addAnimation:(CAAnimation *)animation
{
  animation.timingFunction = CAMediaTimingFunctionFromNSViewAnimationCurve(self.curve);
  animation.duration = self.duration;
  animation.beginTime = _animationBeginTime + self.delay;
  animation.repeatCount = self.repeatCount;
  animation.autoreverses = self.repeatAutoreverses;
  animation.fillMode = kCAFillModeBackwards;
  animation.delegate = self;
  animation.removedOnCompletion = YES;
  _waitingAnimations++;
  return animation;
}

- (id)actionForView:(NSView *)view forKey:(NSString *)keyPath
{
  @synchronized(runningAnimationGroups) {
    [_animatingViews addObject:view];
  }

  if (_transitionView && self.transition != NSViewAnimationGroupTransitionNone) {
    return nil;
  } else {
    CALayer *layer = view.layer;
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:keyPath];
    animation.fromValue = self.beginsFromCurrentState? [layer.presentationLayer valueForKey:keyPath] : [layer valueForKey:keyPath];
    return [self addAnimation:animation];
  }
}

- (void)commit
{
  if (_transitionView && self.transition != NSViewAnimationGroupTransitionNone) {
    CATransition *trans = [CATransition animation];

    switch (self.transition) {
      case NSViewAnimationGroupTransitionFlipFromLeft:
        trans.type = kCATransitionPush;
        trans.subtype = kCATransitionFromLeft;
        break;

      case NSViewAnimationGroupTransitionFlipFromRight:
        trans.type = kCATransitionPush;
        trans.subtype = kCATransitionFromRight;
        break;

      case NSViewAnimationGroupTransitionFlipFromTop:
        trans.type = kCATransitionPush;
        trans.subtype = kCATransitionFromTop;
        break;

      case NSViewAnimationGroupTransitionFlipFromBottom:
        trans.type = kCATransitionPush;
        trans.subtype = kCATransitionFromBottom;
        break;

      case NSViewAnimationGroupTransitionCurlUp:
        trans.type = kCATransitionReveal;
        trans.subtype = kCATransitionFromTop;
        break;

      case NSViewAnimationGroupTransitionCurlDown:
        trans.type = kCATransitionReveal;
        trans.subtype = kCATransitionFromBottom;
        break;

      case NSViewAnimationGroupTransitionCrossDissolve:
      default:
        trans.type = kCATransitionFade;
        break;
    }

    [_animatingViews addObject:_transitionView];
    [_transitionView.layer addAnimation:[self addAnimation:trans] forKey:kCATransition];
  }

  _waitingAnimations--;
  [self notifyAnimationsDidStopIfNeededUsingStatus:YES];
}

@end


static NSMutableArray *_animationGroups;
static BOOL _animationsEnabled = YES;

@implementation NSViewBlockAnimationDelegate
@synthesize completion=_completion, ignoreInteractionEvents=_ignoreInteractionEvents;


- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished
{
  if (_completion) {
    _completion([finished boolValue]);
  }

  if (_ignoreInteractionEvents) {

  }
}

@end

@implementation NSView (NSViewAnimationWithBlocks)

+ (void)animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(NSViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion
{
  if (!_animationGroups) {
    _animationGroups = [[NSMutableArray alloc] init];
  }
  [self _beginAnimationsWithOptions:options | NSViewAnimationOptionTransitionNone];
  [self setAnimationDuration:duration];
  [self setAnimationDelay:delay];
  [self _setAnimationCompletionBlock:completion];

  animations();

  [self commitAnimations];
}

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion
{
  [self animateWithDuration:duration
                      delay:0
                    options:NSViewAnimationOptionCurveEaseInOut
                 animations:animations
                 completion:completion];
}

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations
{
  [self animateWithDuration:duration animations:animations completion:NULL];
}


//+ (void)beginAnimations:(NSString *)animationID context:(void *)context
//{
//    [_animationGroups addObject:[NSViewAnimationGroup animationGroupWithName:animationID context:context]];
//}

+ (void)commitAnimations
{
  if ([_animationGroups count] > 0) {
    [[_animationGroups lastObject] commit];
    [_animationGroups removeLastObject];
  }
}

+ (void)setAnimationBeginsFromCurrentState:(BOOL)beginFromCurrentState
{
  [[_animationGroups lastObject] setBeginsFromCurrentState:beginFromCurrentState];
}

+ (void)setAnimationCurve:(NSViewAnimationCurve)curve
{
  [[_animationGroups lastObject] setCurve:curve];
}

+ (void)setAnimationDelay:(NSTimeInterval)delay
{
  [[_animationGroups lastObject] setDelay:delay];
}

+ (void)setAnimationDelegate:(id)delegate
{
  [[_animationGroups lastObject] setDelegate:delegate];
}

+ (void)setAnimationDidStopSelector:(SEL)selector
{
  [[_animationGroups lastObject] setDidStopSelector:selector];
}

+ (void)setAnimationDuration:(NSTimeInterval)duration
{
  [[_animationGroups lastObject] setDuration:duration];
}

+ (void)setAnimationRepeatAutoreverses:(BOOL)repeatAutoreverses
{
  [[_animationGroups lastObject] setRepeatAutoreverses:repeatAutoreverses];
}

+ (void)setAnimationRepeatCount:(float)repeatCount
{
  [[_animationGroups lastObject] setRepeatCount:repeatCount];
}

+ (void)setAnimationWillStartSelector:(SEL)selector
{
  [[_animationGroups lastObject] setAnimationWillStartSelector:selector];
}

+ (void)_setAnimationTransitionView:(NSView *)view
{
  [[_animationGroups lastObject] setTransitionView:view shouldCache:NO];
}

+ (void)_setAnimationCompletionBlock:(void (^)(BOOL finished))completion
{
  [(NSViewAnimationGroup *)[_animationGroups lastObject] setCompletionBlock:completion];
}

+ (void)_beginAnimationsWithOptions:(NSViewAnimationOptions)options
{
  NSViewAnimationGroup *group = [[NSViewAnimationGroup alloc] initWithAnimationOptions:options];
  [_animationGroups addObject:group];
}

+ (void)transitionWithView:(NSView *)view duration:(NSTimeInterval)duration options:(NSViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion
{
  [self _beginAnimationsWithOptions:options];
  [self setAnimationDuration:duration];
  [self _setAnimationCompletionBlock:completion];
  [self _setAnimationTransitionView:view];

  if (animations) {
    animations();
  }

  [self commitAnimations];
}

+ (void)transitionFromView:(NSView *)fromView toView:(NSView *)toView duration:(NSTimeInterval)duration options:(NSViewAnimationOptions)options completion:(void (^)(BOOL finished))completion
{
  [self transitionWithView:fromView.superview
                  duration:duration
                   options:options
                animations:^{
                  if (NSViewAnimationOptionIsSet(options, NSViewAnimationOptionShowHideTransitionViews)) {
                    fromView.hidden = YES;
                    toView.hidden = NO;
                  } else {
                    [fromView.superview addSubview:toView];
                    [fromView removeFromSuperview];
                  }
                }
                completion:completion];
}

+ (void)setAnimationTransition:(NSViewAnimationTransition)transition forView:(NSView *)view cache:(BOOL)cache
{
  [self _setAnimationTransitionView:view];

  switch (transition) {
    case NSViewAnimationTransitionNone:
      [[_animationGroups lastObject] setTransition:NSViewAnimationGroupTransitionNone];
      break;

    case NSViewAnimationTransitionFlipFromLeft:
      [[_animationGroups lastObject] setTransition:NSViewAnimationGroupTransitionFlipFromLeft];
      break;

    case NSViewAnimationTransitionFlipFromRight:
      [[_animationGroups lastObject] setTransition:NSViewAnimationGroupTransitionFlipFromRight];
      break;

    case NSViewAnimationTransitionCurlUp:
      [[_animationGroups lastObject] setTransition:NSViewAnimationGroupTransitionCurlUp];
      break;

    case NSViewAnimationTransitionCurlDown:
      [[_animationGroups lastObject] setTransition:NSViewAnimationGroupTransitionCurlDown];
      break;
  }
}

- (id)actionForLayer:(CALayer *)theLayer forKey:(NSString *)event
{
  if (_animationsEnabled && [_animationGroups lastObject] && theLayer == _layer) {
    return [[_animationGroups lastObject] actionForView:self forKey:event] ?: (id)[NSNull null];
  } else {
    return [NSNull null];
  }
}


+ (BOOL)areAnimationsEnabled
{
  return _animationsEnabled;
}

+ (void)setAnimationsEnabled:(BOOL)enabled
{
  _animationsEnabled = enabled;
}

@end
