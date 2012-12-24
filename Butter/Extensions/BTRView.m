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
	BOOL drawFlag;
}

#pragma mark Properties

BTRVIEW_ADDITIONS_IMPLEMENTATION();

- (void)setFlipped:(BOOL)flipped
{
	if (_flipped != flipped) {
		_flipped = flipped;
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

- (void)setAnimateContents:(BOOL)animateContents {
	drawFlag = animateContents;
	_animateContents = animateContents;
}

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event {
	if ([event isEqualToString:@"contents"] && self.animateContents) {
		self.animateContents = drawFlag;
		CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"contents"];
		return animation;
	}
	
	return [super actionForLayer:layer forKey:event];
}

#pragma mark Drawing block

//- (void)drawRect:(NSRect)dirtyRect {
//	[super drawRect:dirtyRect];
//	
//	if (self.drawRectBlock != nil) {
//		NSLog(@"%s",__PRETTY_FUNCTION__);
//		CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
//		self.drawRectBlock(self, ctx);
//	}
//}

@end
