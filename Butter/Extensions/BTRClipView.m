//
//  BTRClipView.m
//  Originally from Rebel
//
//  Created by Justin Spahr-Summers on 2012-09-14.
//  Modified by Jonathan Willing
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "BTRClipView.h"

@implementation BTRClipView

#pragma mark Properties

@dynamic layer;

- (NSColor *)backgroundColor {
	return [NSColor colorWithCGColor:self.layer.backgroundColor];
}

- (void)setBackgroundColor:(NSColor *)color {
	self.layer.backgroundColor = color.CGColor;
}

- (BOOL)isOpaque {
	return self.layer.opaque;
}

- (void)setOpaque:(BOOL)opaque {
	self.layer.opaque = opaque;
}

#pragma mark Lifecycle

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self == nil) return nil;

	self.layer = [CAScrollLayer layer];
	self.wantsLayer = YES;

	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawNever;

	// Matches default NSClipView settings.
	self.backgroundColor = NSColor.clearColor;
	self.opaque = NO;

	return self;
}

- (void)scrollToPoint:(NSPoint)newOrigin {
	[super scrollToPoint:newOrigin];
	NSLog(@"%s",__PRETTY_FUNCTION__);
}

- (BOOL)scrollRectToVisible:(NSRect)aRect animated:(BOOL)animated {
	return [super scrollRectToVisible:aRect];
	NSLog(@"%s",__PRETTY_FUNCTION__);
}

@end
