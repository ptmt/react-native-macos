//
//  NSView+NSViewAnimationWithBlocks.m
//  Mail
//
//  Created by Robert Widmann on 7/13/12.
//  Copyright (c) 2012 CodaFi Inc. All rights reserved.
//
//  Taken from https://github.com/jasonwiener/Mail/

#import "NSView+NSViewAnimationWithBlocks.h"
#import <QuartzCore/QuartzCore.h>

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

@implementation NSViewAnimationGroup

- (id)initWithGroupName:(NSString *)theName context:(void *)theContext
{
    if ((self=[super init])) {
        _name = [theName copy];
        _context = theContext;
        _waitingAnimations = 1;
        _animationDuration = 0.2;
        _animationCurve = NSViewAnimationCurveEaseInOut;
        _animationBeginsFromCurrentState = NO;
        _animationRepeatAutoreverses = NO;
        _animationRepeatCount = 0;
        _animationBeginTime = CACurrentMediaTime();
        _animatingViews = [[NSMutableSet alloc] initWithCapacity:0];
    }
    return self;
}

+ (id)animationGroupWithName:(NSString *)theName context:(void *)theContext
{
    return [[self alloc] initWithGroupName:theName context:theContext];
}

- (void)notifyAnimationsDidStopIfNeededUsingStatus:(BOOL)animationsDidFinish
{
    if (_waitingAnimations == 0) {
        if ([_animationDelegate respondsToSelector:_animationDidStopSelector]) {
            NSMethodSignature *signature = [_animationDelegate methodSignatureForSelector:_animationDidStopSelector];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setSelector:_animationDidStopSelector];
            NSInteger remaining = [signature numberOfArguments] - 2;

            NSNumber *finishedArgument = [NSNumber numberWithBool:animationsDidFinish];

            if (remaining > 0) {
                [invocation setArgument:&_name atIndex:2];
                remaining--;
            }

            if (remaining > 0) {
                [invocation setArgument:&finishedArgument atIndex:3];
                remaining--;
            }

            if (remaining > 0) {
                [invocation setArgument:&_context atIndex:4];
            }

            [invocation invokeWithTarget:_animationDelegate];
        }
        [_animatingViews removeAllObjects];
    }
}

- (void)animationDidStart:(CAAnimation *)theAnimation
{
    if (!_didSendStartMessage) {
        if ([_animationDelegate respondsToSelector:_animationWillStartSelector]) {
            NSMethodSignature *signature = [_animationDelegate methodSignatureForSelector:_animationWillStartSelector];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setSelector:_animationWillStartSelector];
            NSInteger remaining = [signature numberOfArguments] - 2;

            if (remaining > 0) {
                [invocation setArgument:&_name atIndex:2];
                remaining--;
            }

            if (remaining > 0) {
                [invocation setArgument:&_context atIndex:3];
            }

            [invocation invokeWithTarget:_animationDelegate];
        }
        _didSendStartMessage = YES;
    }
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    _waitingAnimations--;
    [self notifyAnimationsDidStopIfNeededUsingStatus:flag];
}

- (CAAnimation *)addAnimation:(CAAnimation *)animation
{
    animation.timingFunction = CAMediaTimingFunctionFromNSViewAnimationCurve(_animationCurve);
    animation.duration = _animationDuration;
    animation.beginTime = _animationBeginTime + _animationDelay;
    animation.repeatCount = _animationRepeatCount;
    animation.autoreverses = _animationRepeatAutoreverses;
    animation.fillMode = kCAFillModeBackwards;
    animation.delegate = self;
    animation.removedOnCompletion = YES;
    _waitingAnimations++;
    return animation;
}

- (id)actionForView:(NSView *)view forKey:(NSString *)keyPath
{
    [_animatingViews addObject:view];
    CALayer *layer = view.layer;
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:keyPath];
    animation.fromValue = _animationBeginsFromCurrentState? [layer.presentationLayer valueForKey:keyPath] : [layer valueForKey:keyPath];
    return [self addAnimation:animation];
}

- (void)setAnimationBeginsFromCurrentState:(BOOL)beginFromCurrentState
{
    _animationBeginsFromCurrentState = beginFromCurrentState;
}

- (void)setAnimationCurve:(NSViewAnimationCurve)curve
{
    _animationCurve = curve;
}

- (void)setAnimationDelay:(NSTimeInterval)delay
{
    _animationDelay = delay;
}

- (void)setAnimationDelegate:(id)delegate
{
    if (delegate != _animationDelegate) {
        _animationDelegate = delegate;
    }
}

- (void)setAnimationDidStopSelector:(SEL)selector
{
    _animationDidStopSelector = selector;
}

- (void)setAnimationDuration:(NSTimeInterval)newDuration
{
    _animationDuration = newDuration;
}

- (void)setAnimationRepeatAutoreverses:(BOOL)repeatAutoreverses
{
    _animationRepeatAutoreverses = repeatAutoreverses;
}

- (void)setAnimationRepeatCount:(float)repeatCount
{
    _animationRepeatCount = repeatCount;
}

- (void)setAnimationTransition:(NSViewAnimationTransition)transition forView:(NSView *)view cache:(BOOL)cache
{
    _transitionLayer = view.layer;
    _transitionType = transition;
    _transitionShouldCache = cache;
}

- (void)setAnimationWillStartSelector:(SEL)selector
{
    _animationWillStartSelector = selector;
}


- (void)commit
{
    if (_transitionLayer) {
        CATransition *trans = [CATransition animation];
        trans.type = kCATransitionMoveIn;

        switch (_transitionType) {
            case NSViewAnimationTransitionNone:				trans.subtype = nil;						break;
            case NSViewAnimationTransitionCurlUp:			trans.subtype = kCATransitionFromTop;		break;
            case NSViewAnimationTransitionCurlDown:			trans.subtype = kCATransitionFromBottom;	break;
            case NSViewAnimationTransitionFlipFromLeft:		trans.subtype = kCATransitionFromLeft;		break;
            case NSViewAnimationTransitionFlipFromRight:	trans.subtype = kCATransitionFromRight;		break;
        }

        [_transitionLayer addAnimation:[self addAnimation:trans] forKey:kCATransition];
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

+ (void)animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(NSViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion {

    if (_animationGroups == nil) {
        _animationGroups = [[NSMutableArray alloc] init];
    }

    const BOOL ignoreInteractionEvents = !((options & NSViewAnimationOptionAllowUserInteraction) == NSViewAnimationOptionAllowUserInteraction);
    const BOOL repeatAnimation = ((options & NSViewAnimationOptionRepeat) == NSViewAnimationOptionRepeat);
    const BOOL autoreverseRepeat = ((options & NSViewAnimationOptionAutoreverse) == NSViewAnimationOptionAutoreverse);
    const BOOL beginFromCurrentState = ((options & NSViewAnimationOptionBeginFromCurrentState) == NSViewAnimationOptionBeginFromCurrentState);
    NSViewAnimationCurve animationCurve;

    animationCurve = (options >> 16) & 0x03;

    // NOTE: As of iOS 5 this is only supposed to block interaction events for the views being animated, not the whole app.
    if (ignoreInteractionEvents) {

    }

    NSViewBlockAnimationDelegate *delegate = [[NSViewBlockAnimationDelegate alloc] init];
    delegate.completion = completion;
    delegate.ignoreInteractionEvents = ignoreInteractionEvents;

    [NSView beginAnimations:nil context:NULL];
    [NSView setAnimationCurve:animationCurve];
    [NSView setAnimationDelay:delay];
    [NSView setAnimationDuration:duration];
    [NSView setAnimationBeginsFromCurrentState:beginFromCurrentState];
    [NSView setAnimationDelegate:delegate];	// this is retained here
    [NSView setAnimationDidStopSelector:@selector(animationDidStop:finished:)];
    [NSView setAnimationRepeatCount:(repeatAnimation? FLT_MAX : 0)];
    [NSView setAnimationRepeatAutoreverses:autoreverseRepeat];

    animations();

    [NSView commitAnimations];
}

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion {
    [self animateWithDuration:duration delay:0.0 options:0 animations:animations completion:completion];

}// delay = 0.0, options = 0

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations {
    [self animateWithDuration:duration delay:0.0 options:0 animations:animations completion:NULL];
}// delay = 0.0, options = 0, completion = NULL


+ (void)beginAnimations:(NSString *)animationID context:(void *)context
{
    [_animationGroups addObject:[NSViewAnimationGroup animationGroupWithName:animationID context:context]];
}

+ (void)commitAnimations
{
    if ([_animationGroups count] > 0) {
        [[_animationGroups lastObject] commit];
        [_animationGroups removeLastObject];
    }
}

+ (void)setAnimationBeginsFromCurrentState:(BOOL)beginFromCurrentState
{
    [[_animationGroups lastObject] setAnimationBeginsFromCurrentState:beginFromCurrentState];
}

+ (void)setAnimationCurve:(NSViewAnimationCurve)curve
{
    [[_animationGroups lastObject] setAnimationCurve:curve];
}

+ (void)setAnimationDelay:(NSTimeInterval)delay
{
    [[_animationGroups lastObject] setAnimationDelay:delay];
}

+ (void)setAnimationDelegate:(id)delegate
{
    [[_animationGroups lastObject] setAnimationDelegate:delegate];
}

+ (void)setAnimationDidStopSelector:(SEL)selector
{
    [[_animationGroups lastObject] setAnimationDidStopSelector:selector];
}

+ (void)setAnimationDuration:(NSTimeInterval)duration
{
    [[_animationGroups lastObject] setAnimationDuration:duration];
}

+ (void)setAnimationRepeatAutoreverses:(BOOL)repeatAutoreverses
{
    [[_animationGroups lastObject] setAnimationRepeatAutoreverses:repeatAutoreverses];
}

+ (void)setAnimationRepeatCount:(float)repeatCount
{
    [[_animationGroups lastObject] setAnimationRepeatCount:repeatCount];
}

+ (void)setAnimationWillStartSelector:(SEL)selector
{
    [[_animationGroups lastObject] setAnimationWillStartSelector:selector];
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
