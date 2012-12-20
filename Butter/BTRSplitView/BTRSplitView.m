//
//  BTRSplitView.m
//  Butter
//
//  Created by Robert Widmann on 12/8/12.
//  Copyright (c) 2012 CodaFi. All rights reserved.
//  Thanks to http://jhaberstro.blogspot.com/2012/05/animating-nssplitview.html

#import "BTRSplitView.h"
#import "NSView+BTRAdditions.h"
#import <QuartzCore/QuartzCore.h>

static CGFloat const kBTRSplitViewAnimationDuration = .25;
static NSString * const kBTRSplitViewDividerPositionKey = @"dividerPosition";

@implementation BTRSplitView

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self == nil) return nil;
	[self commonInit];
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self == nil) return nil;
	[self commonInit];
	return self;
}

- (void)commonInit {
	self.wantsLayer = YES;
	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
}

#pragma mark - Drawing

- (void)drawDividerInRect:(NSRect)rect {
	if (self.dividerDrawRectBlock == nil) {
		return [super drawDividerInRect:rect];
	} else {
		CGContextRef ctx = [NSGraphicsContext currentContext].graphicsPort;
		self.dividerDrawRectBlock(self, ctx, rect, [self _dividerIndexFromRect:rect]);
	}
}

#pragma mark - Position

- (void)setPosition:(CGFloat)position ofDividerAtIndex:(NSInteger)dividerIndex {
	[self setPosition:position ofDividerAtIndex:dividerIndex animated:NO];
}

- (void)setPosition:(CGFloat)position ofDividerAtIndex:(NSInteger)dividerIndex animated:(BOOL)animate {
	if (!animate) {
		[super setPosition:position ofDividerAtIndex:dividerIndex];
		return;
	}
	
	NSView *resizingSubview = [self.subviews objectAtIndex:dividerIndex];
	
	[NSView btr_animateWithDuration:kBTRSplitViewAnimationDuration animationCurve:BTRViewAnimationCurveEaseInOut animations:^{
		[self.animator setValue:@(position) forKey:[kBTRSplitViewDividerPositionKey stringByAppendingFormat:@"%li",(long)dividerIndex]];
	} completion:^{
		if (position == 0) {
			//If the end value is zero, we assume a collapse, which means hiding the subview
			[resizingSubview setHidden:YES];
		}
	}];
}

- (id)valueForUndefinedKey:(NSString *)key {
	if ([key rangeOfString:kBTRSplitViewDividerPositionKey].location != NSNotFound) {
		return @([self positionOfDividerAtIndex:[[[key componentsSeparatedByString:kBTRSplitViewDividerPositionKey] lastObject] integerValue]]);
	}
	
	return nil;
}

- (id)animationForKey:(NSString *)key {
    if ([key rangeOfString:kBTRSplitViewDividerPositionKey].location != NSNotFound) {
		CABasicAnimation *animation = [CABasicAnimation animation];
		return animation;
    }
	
    return [super animationForKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
	if ([key rangeOfString:kBTRSplitViewDividerPositionKey].location != NSNotFound) {
		NSInteger index = [[[key componentsSeparatedByString:kBTRSplitViewDividerPositionKey] lastObject] integerValue];
		[super setPosition:[value floatValue] ofDividerAtIndex:index];
	} else {
		[super setValue:value forUndefinedKey:key];
	}
}

- (CGFloat)positionOfDividerAtIndex:(NSInteger)dividerIndex {
	if (dividerIndex > self.subviews.count) {
	 	return 0;
	}
	
	NSView *subview = self.subviews[dividerIndex];
	NSRect frame = subview.frame;
	
	if(self.isVertical) {
		return frame.origin.x + frame.size.width;
	} else {
		return frame.origin.y + frame.size.height;
	}
}

#pragma mark - Private

- (NSInteger)_dividerIndexFromRect:(NSRect)rect {
	NSInteger result = 0;
	if (self.subviews.count == 2) {
		return result;
	}
	// Adjust the passed in rect by it's divider thickness so we can try to ping
	// the subview adjacent to it.  (either to the left, or above it).
	NSRect adjustedRect = rect;
	if (self.isVertical) {
		adjustedRect.origin.x -= 1; //Left one pixel
	} else {
		adjustedRect.origin.y += self.dividerThickness + 1; //Up the divider's thickness plus some padding
	}
	// Loop through our subviews to get the index of the view adjacent to the divider.
	for (int i = 0; i < self.subviews.count; i++) {
		NSView *subview = [self.subviews objectAtIndex:i];
		if (!CGRectIntersectsRect(subview.frame, adjustedRect)) continue;
		result = i;
	}
	return result;
}

@end
