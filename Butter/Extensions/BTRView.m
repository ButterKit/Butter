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

- (id)initWithFrame:(NSRect)frame layerHosted:(BOOL)hostsLayer {
	self = [super initWithFrame:frame];
	if (self == nil) return nil;
	
	if (hostsLayer) {
		self.layer = [CALayer layer];
		self.layer.delegate = self;
	}
	[self commonInitForBTRView];
	
	return self;
}

- (id)initWithFrame:(NSRect)frame {
	return [self initWithFrame:frame layerHosted:NO];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self == nil) return nil;
	
	[self commonInitForBTRView];
	
	return self;
}

- (void)commonInitForBTRView {
	self.wantsLayer = YES;
	self.layerContentsPlacement = NSViewLayerContentsPlacementScaleAxesIndependently;
	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
}


#pragma mark NSObject

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p>{ frame = %@, layer = <%@: %p> }", self.class, self, NSStringFromRect(self.frame), self.layer.class, self.layer];
}


#pragma mark Drawing and actions

- (void)displayAnimated {
	drawFlag = self.animatesContents;
	self.animatesContents = YES;
	[self display];
}

- (void)setAnimatesContents:(BOOL)animate {
	drawFlag = animate;
	_animatesContents = animate;
}

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event {
	if ([event isEqualToString:@"contents"]) {
		if (!self.animatesContents) {
			return (id<CAAction>)[NSNull null];
		}
		self.animatesContents = drawFlag;
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
