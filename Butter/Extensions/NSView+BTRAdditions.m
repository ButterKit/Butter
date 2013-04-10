//
//  NSView+BTRAdditions.m
//  Originally from Rebel
//
//  Created by Justin Spahr-Summers on 2012-09-04.
//	Modified by Jonathan Willing
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSView+BTRAdditions.h"
#import "BTRClipView.h"
#import <QuartzCore/CAMediaTimingFunction.h>

static NSUInteger BTRAnimationContextCount = 0;

@implementation NSView (BTRAnimationAdditions)

#pragma mark Animations

+ (void)btr_animate:(void (^)(void))animations {
	[self btr_animate:animations completion:nil];
}

+ (void)btr_animate:(void (^)(void))animations completion:(void (^)(void))completion {
	// It's not clear whether NSAnimationContext will accept a nil completion block.
	if (completion == nil) completion = ^{};
	
	// If we're in an animation block, just enable implicit animations
	if ([self btr_isInAnimationContext]) {
		NSAnimationContext.currentContext.allowsImplicitAnimation = YES;
		animations();
		completion();
		return;
	}
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		BTRAnimationContextCount++;
		NSAnimationContext.currentContext.allowsImplicitAnimation = YES;
		animations();
		NSAnimationContext.currentContext.allowsImplicitAnimation = NO;
		BTRAnimationContextCount--;
	} completionHandler:completion];
}

+ (void)btr_animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(void))completion {
	if (![self btr_isInAnimationContext])
		NSAnimationContext.currentContext.duration = duration;
	[self btr_animate:animations completion:completion];
}

+ (void)btr_animateWithDuration:(NSTimeInterval)duration animationCurve:(BTRViewAnimationCurve)curve animations:(void (^)(void))animations completion:(void (^)(void))completion {
	if (![self btr_isInAnimationContext])
		NSAnimationContext.currentContext.timingFunction = [self btr_timingFunctionWithCurve:curve];
	[self btr_animateWithDuration:duration animations:animations completion:completion];
}

+ (BOOL)btr_isInAnimationContext {
	return BTRAnimationContextCount > 0;
}

- (void)btr_scrollRectToVisible:(NSRect)rect animated:(BOOL)animated {
	NSClipView *clipView = [[self enclosingScrollView] contentView];
	if ([clipView isKindOfClass:BTRClipView.class]) {
		[(BTRClipView *)clipView scrollRectToVisible:rect animated:animated];
	} else {
		if (animated) {
			[(NSClipView *)[clipView animator] scrollRectToVisible:rect];
		}
		else {
			[clipView scrollRectToVisible:rect];
		}
	}
}

#pragma mark Timing

+ (CAMediaTimingFunction *)btr_timingFunctionWithCurve:(BTRViewAnimationCurve)curve {
	switch (curve) {
		case BTRViewAnimationCurveEaseInOut:
			return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			break;
		case BTRViewAnimationCurveEaseIn:
			return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
			break;
		case BTRViewAnimationCurveEaseOut:
			return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
			break;
		case BTRViewAnimationCurveLinear:
			return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
			break;			
		default:
			break;
	}
	return nil;
}

@end
