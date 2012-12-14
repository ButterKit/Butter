//
//  BTRView.m
//  Originally from Rebel
//
//  Created by Justin Spahr-Summers on 2012-07-29.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "BTRView.h"
#import "BTRCommon.h"
#import <QuartzCore/QuartzCore.h>

@implementation BTRView {
	BOOL btr_flipped;
	BOOL drawFlag;
}

#pragma mark Properties

BTRVIEW_ADDITIONS_IMPLEMENTATION();

- (BOOL)isFlipped
{
	return btr_flipped;
}

- (void)setFlipped:(BOOL)flipped
{
	if (flipped != btr_flipped) {
		btr_flipped = flipped;
		self.needsLayout = YES;
		self.needsDisplay = YES;
	}
}

#pragma mark Lifecycle

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self == nil) return nil;

	self.wantsLayer = YES;
	self.layerContentsPlacement = NSViewLayerContentsPlacementScaleAxesIndependently;
	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	
	return self;
}

#pragma mark NSObject

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p>{ frame = %@, layer = <%@: %p> }", self.class, self, NSStringFromRect(self.frame), self.layer.class, self.layer];
}

#pragma mark Drawing and actions

- (void)displayAnimated {
	drawFlag = self.animateContents;
	self.animateContents = YES;
	[self display];
}

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event {
	if ([event isEqualToString:@"contents"] && self.animateContents) {
		self.animateContents = drawFlag;
		CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"contents"];
		return animation;
	}
	
	return [super actionForLayer:layer forKey:event];
}

@end
