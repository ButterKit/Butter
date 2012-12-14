//
//  NSView+BTRAdditions.h
//  Originally from Rebel
//
//  Created by Justin Spahr-Summers on 2012-09-04.
//	Updated by Jonathan Willing
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, BTRViewAnimationCurve) {
    BTRViewAnimationCurveEaseInOut,
    BTRViewAnimationCurveEaseIn,
    BTRViewAnimationCurveEaseOut,
    BTRViewAnimationCurveLinear
};

// Better block-based animation and animator proxies.
@interface NSView (BTRAnimationAdditions)

// Invokes +btr_animate:completion: with a nil completion block.
+ (void)btr_animate:(void (^)(void))animations;

// Executes the given animation block within a new NSAnimationContext. When all
// animations in the group complete or are canceled, the given completion block
// (if not nil) will be invoked. Implicit animation is turned on by default.
+ (void)btr_animate:(void (^)(void))animations completion:(void (^)(void))completion;

// Invokes +btr_animate:completion:, setting the animation duration of the
// context before queuing the given animations.
+ (void)btr_animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(void))completion;

// Invokes +btr_animateWithDuration:animations:completion: with the added ability to set
// a timing function on the animation.
+ (void)btr_animateWithDuration:(NSTimeInterval)duration animationCurve:(BTRViewAnimationCurve)curve animations:(void (^)(void))animations completion:(void (^)(void))completion;

// Returns whether the calling code is executing in an animation context created
// by this category (like through -btr_animate:completion:).
//
// This only describes whether an animation context is open, not if animations
// happen to be executing at the moment.
+ (BOOL)btr_isInAnimationContext;

// Returns an animator proxy for the receiver if +btr_isInAnimationContext
// returns YES. Otherwise, the receiver is returned (so that animating is
// effectively disabled).
- (instancetype)btr_animator;

@end
