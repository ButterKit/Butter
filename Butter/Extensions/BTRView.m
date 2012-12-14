//
//  BTRView.m
//  Originally from Rebel
//
//  Created by Justin Spahr-Summers on 2012-07-29.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "BTRView.h"

@interface BTRView () {
	struct {
		unsigned flipped:1;
		unsigned clipsToBounds:1;
		unsigned opaque:1;
	} _flags;
}

// Applies all layer properties that the receiver knows about.
- (void)applyLayerProperties;

@end

@implementation BTRView

#pragma mark Properties

// Implemented by NSView.
@dynamic layerContentsRedrawPolicy;

- (void)setBackgroundColor:(NSColor *)color {
	_backgroundColor = color;
	[self applyLayerProperties];
}

- (void)setCornerRadius:(CGFloat)radius {
	_cornerRadius = radius;
	[self applyLayerProperties];
}

- (BOOL)clipsToBounds {
	return _flags.clipsToBounds;
}

- (void)setClipsToBounds:(BOOL)value {
	_flags.clipsToBounds = (value ? 1 : 0);
	[self applyLayerProperties];
}

- (BOOL)isOpaque {
	return _flags.opaque;
}

- (void)setOpaque:(BOOL)value {
	_flags.opaque = (value ? 1 : 0);
	[self applyLayerProperties];
}

- (BOOL)isFlipped {
	return _flags.flipped;
}

- (void)setFlipped:(BOOL)value {
	if (value == self.flipped) return;

	_flags.flipped = (value ? 1 : 0);

	// Not sure how necessary these are, but it's probably a good idea.
	self.needsLayout = YES;
	self.needsDisplay = YES;
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

#pragma mark View Hierarchy

// Before 10.8, AppKit may destroy the view's layer when changing superviews
// or windows, so reapply our properties when either of those events occur.
- (void)viewDidMoveToSuperview {
	[self applyLayerProperties];
}

- (void)viewDidMoveToWindow {
	[self applyLayerProperties];
}

#pragma mark Layer Management

- (void)applyLayerProperties {
	self.layer.backgroundColor = self.backgroundColor.CGColor;
	self.layer.cornerRadius = self.cornerRadius;
	self.layer.masksToBounds = self.clipsToBounds;
	self.layer.opaque = self.opaque;
}

- (void)setLayer:(CALayer *)layer {
	[super setLayer:layer];
	[self applyLayerProperties];
}

#pragma mark NSObject

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p>{ frame = %@, layer = <%@: %p> }", self.class, self, NSStringFromRect(self.frame), self.layer.class, self.layer];
}

@end
