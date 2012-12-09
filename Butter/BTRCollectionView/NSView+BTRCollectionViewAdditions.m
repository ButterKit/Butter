//
//  Originally from Rebel
//
//  Created by Justin Spahr-Summers on 2012-09-04.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSView+BTRCollectionViewAdditions.h"

static NSUInteger BTRAnimationContextCount = 0;

@implementation NSView (BTRCollectionViewAdditions)

+ (void)btr_animate:(void (^)(void))animations {
	[self btr_animate:animations completion:nil];
}

+ (void)btr_animate:(void (^)(void))animations completion:(void (^)(void))completion {
	// It's not clear whether NSAnimationContext will accept a nil completion
	// block.
	if (completion == nil) completion = ^{};

	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		BTRAnimationContextCount++;
		context.allowsImplicitAnimation = YES;
		animations();
		context.allowsImplicitAnimation = NO;
		BTRAnimationContextCount--;
	} completionHandler:completion];
}

+ (void)btr_animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(void))completion {
	[self btr_animate:^{
		NSAnimationContext.currentContext.duration = duration;
		animations();
	} completion:completion];
}

+ (BOOL)btr_isInAnimationContext {
	return BTRAnimationContextCount > 0;
}

- (instancetype)btr_animator {
	return self.class.btr_isInAnimationContext ? self.animator : self;
}

- (void)btr_scrollRectToVisible:(NSRect)rect animated:(BOOL)animated
{
	NSClipView *clipView = [[self enclosingScrollView] contentView];
	
	// TODO: This will not be a smooth animation.
	if (animated)
		[clipView.btr_animator scrollRectToVisible:rect];
	else
		[clipView scrollRectToVisible:rect];
}

@end
