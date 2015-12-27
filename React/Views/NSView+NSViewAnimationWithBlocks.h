//
//  NSView+NSViewAnimationWithBlocks.h
//  Mail
//
//  Created by Robert Widmann on 7/13/12.
//  Copyright (c) 2012 CodaFi Inc. All rights reserved.
//
//  Taken from //  Taken from https://github.com/jasonwiener/Mail/

#import <Cocoa/Cocoa.h>

typedef NSInteger NSViewAnimationTransition;

enum NSViewAnimationTransition{
    NSViewAnimationTransitionNone,
    NSViewAnimationTransitionFlipFromLeft,
    NSViewAnimationTransitionFlipFromRight,
    NSViewAnimationTransitionCurlUp,
    NSViewAnimationTransitionCurlDown,
};

typedef NSUInteger NSViewAnimationOptions;

enum NSViewAnimationOptions{
    NSViewAnimationOptionLayoutSubviews            = 1 <<  0,
    NSViewAnimationOptionAllowUserInteraction      = 1 <<  1, // turn on user interaction while animating
    NSViewAnimationOptionBeginFromCurrentState     = 1 <<  2, // start all views from current value, not initial value
    NSViewAnimationOptionRepeat                    = 1 <<  3, // repeat animation indefinitely
    NSViewAnimationOptionAutoreverse               = 1 <<  4, // if repeat, run animation back and forth
    NSViewAnimationOptionOverrideInheritedDuration = 1 <<  5, // ignore nested duration
    NSViewAnimationOptionOverrideInheritedCurve    = 1 <<  6, // ignore nested curve
    NSViewAnimationOptionAllowAnimatedContent      = 1 <<  7, // animate contents (applies to transitions only)
    NSViewAnimationOptionShowHideTransitionViews   = 1 <<  8, // flip to/from hidden state instead of adding/removing

    NSViewAnimationOptionCurveEaseInOut            = 0 << 16, // default
    NSViewAnimationOptionCurveEaseIn               = 1 << 16,
    NSViewAnimationOptionCurveEaseOut              = 2 << 16,
    NSViewAnimationOptionCurveLinear               = 3 << 16,

    NSViewAnimationOptionTransitionNone            = 0 << 20, // default
    NSViewAnimationOptionTransitionFlipFromLeft    = 1 << 20,
    NSViewAnimationOptionTransitionFlipFromRight   = 2 << 20,
    NSViewAnimationOptionTransitionCurlUp          = 3 << 20,
    NSViewAnimationOptionTransitionCurlDown        = 4 << 20,
    NSViewAnimationOptionTransitionCrossDissolve   = 5 << 20,
    NSViewAnimationOptionTransitionFlipFromTop     = 6 << 20,
    NSViewAnimationOptionTransitionFlipFromBottom  = 7 << 20,
};

typedef NSInteger NSViewAnimationCurve;

enum NSViewAnimationCurve{
    NSViewAnimationCurveEaseInOut,         // slow at beginning and end
    NSViewAnimationCurveEaseIn,            // slow at beginning
    NSViewAnimationCurveEaseOut,           // slow at end
    NSViewAnimationCurveLinear
};

@interface NSView (NSViewAnimationWithBlocks)

+ (void)animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(NSViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion;

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion; // delay = 0.0, options = 0

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations; // delay = 0.0, options = 0, completion = NULL

+ (void)beginAnimations:(NSString *)animationID context:(void *)context;
+ (void)commitAnimations;
+ (void)setAnimationBeginsFromCurrentState:(BOOL)beginFromCurrentState;
+ (void)setAnimationCurve:(NSViewAnimationCurve)curve;
+ (void)setAnimationDelay:(NSTimeInterval)delay;
+ (void)setAnimationDelegate:(id)delegate;
+ (void)setAnimationDidStopSelector:(SEL)selector;
+ (void)setAnimationDuration:(NSTimeInterval)duration;
+ (void)setAnimationRepeatAutoreverses:(BOOL)repeatAutoreverses;
+ (void)setAnimationRepeatCount:(float)repeatCount;
+ (void)setAnimationWillStartSelector:(SEL)selector;
+ (BOOL)areAnimationsEnabled;
+ (void)setAnimationsEnabled:(BOOL)enabled;

@end

@interface NSViewBlockAnimationDelegate : NSObject {
    void (^_completion)(BOOL finished);
    BOOL _ignoreInteractionEvents;
}

@property (nonatomic, copy) void (^completion)(BOOL finished);
@property (nonatomic, assign) BOOL ignoreInteractionEvents;

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished;

@end

@interface NSViewAnimationGroup : NSObject {
@private
    NSString *_name;
    void *_context;
    NSUInteger _waitingAnimations;
    BOOL _didSendStartMessage;
    NSTimeInterval _animationDelay;
    NSTimeInterval _animationDuration;
    NSViewAnimationCurve _animationCurve;
    NSViewAnimationTransition _transitionType;
    id _animationDelegate;
    SEL _animationDidStopSelector;
    SEL _animationWillStartSelector;
    BOOL _animationBeginsFromCurrentState;
    BOOL _animationRepeatAutoreverses;
    float _animationRepeatCount;
    CFTimeInterval _animationBeginTime;
    CALayer *_transitionLayer;
    BOOL _transitionShouldCache;
    NSMutableSet *_animatingViews;
}

+ (id)animationGroupWithName:(NSString *)theName context:(void *)theContext;

- (id)actionForView:(NSView *)view forKey:(NSString *)keyPath;

- (void)setAnimationBeginsFromCurrentState:(BOOL)beginFromCurrentState;
- (void)setAnimationCurve:(NSViewAnimationCurve)curve;
- (void)setAnimationDelay:(NSTimeInterval)delay;
- (void)setAnimationDelegate:(id)delegate;			// retained! (also true of the real UIKit)
- (void)setAnimationDidStopSelector:(SEL)selector;
- (void)setAnimationDuration:(NSTimeInterval)duration;
- (void)setAnimationRepeatAutoreverses:(BOOL)repeatAutoreverses;
- (void)setAnimationRepeatCount:(float)repeatCount;
- (void)setAnimationWillStartSelector:(SEL)selector;

- (void)commit;

@end
