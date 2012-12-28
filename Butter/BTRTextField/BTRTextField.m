//
//  BTRTextField.m
//  Butter
//
//  Created by Jonathan Willing on 12/21/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import "BTRTextField.h"
#import <QuartzCore/QuartzCore.h>

@interface BTRTextField()
@property (nonatomic, readonly, getter = isFirstResponder) BOOL firstResponder;
@end

const CGFloat BTRTextFieldCornerRadius = 3.f;
const CGFloat BTRTextFieldInnerRadius = 2.f;

@implementation BTRTextField

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
	self.focusRingType = NSFocusRingTypeNone;
	self.drawsBackground = NO;
	self.bezeled = NO;
	
	// Set up the layer styles used to draw a focus ring.
	self.layer.shadowColor = [NSColor colorWithCalibratedRed:0.176 green:0.490 blue:0.898 alpha:1].CGColor;
	self.layer.shadowOffset = CGSizeZero;
	self.layer.shadowRadius = 2.f;
}

// NSTextField is flipped by default.
// Switch it back to normal drawing behaviour.
- (BOOL)isFlipped {
	return NO;
}

// It appears that on some layer-backed view heirarchies that are
// set up before the window has a chance to be shown, the text fields
// aren't set up properly. This temporarily alleviates this problem.
//
// TODO: Investigate this more.
- (void)viewDidMoveToWindow {
	[self setNeedsDisplay:YES];
}


#pragma mark Drawing

- (void)drawRect:(NSRect)dirtyRect {
	[[NSColor whiteColor] set];
	if (![self isFirstResponder])
		[[NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:BTRTextFieldCornerRadius yRadius:BTRTextFieldCornerRadius] fill];
	
	NSGradient *gradient = nil;
	CGRect borderRect = self.bounds;
	borderRect.size.height -= 1, borderRect.origin.y += 1;
	if([self isFirstResponder]) {
		gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.114 green:0.364 blue:0.689 alpha:1.000] endingColor:[NSColor colorWithCalibratedRed:0.176 green:0.490 blue:0.898 alpha:1]];
	} else {
		gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.6 alpha:1.0] endingColor:[NSColor colorWithDeviceWhite:0.7 alpha:1.0]];
	}
	[gradient drawInBezierPath:[NSBezierPath bezierPathWithRoundedRect:borderRect xRadius:BTRTextFieldCornerRadius yRadius:BTRTextFieldCornerRadius] angle:-90];
	
	[[NSColor whiteColor] set];
	CGRect innerRect = NSInsetRect(self.bounds, 1, 2);
	innerRect.size.height += 1;
	[[NSBezierPath bezierPathWithRoundedRect:innerRect xRadius:BTRTextFieldInnerRadius yRadius:BTRTextFieldInnerRadius] fill];
	
	[super drawRect:dirtyRect];
}

- (CATransition *)shadowOpacityAnimation {
	CATransition *fade = [CATransition animation];
	fade.duration = 0.25;
	fade.type = kCATransitionFade;
	return fade;
}


#pragma mark Responders

- (BOOL)isFirstResponder {
	id firstResponder = self.window.firstResponder;
	return ([firstResponder isKindOfClass:[NSText class]] && [firstResponder delegate] == self);
}

- (BOOL)becomeFirstResponder {
	[self.layer addAnimation:[self shadowOpacityAnimation] forKey:nil];
	self.layer.shadowOpacity = 1.f;
	return [super becomeFirstResponder];
}

- (void)textDidEndEditing:(NSNotification *)notification {
	[self.layer addAnimation:[self shadowOpacityAnimation] forKey:nil];
	self.layer.shadowOpacity = 0.f;
	[super textDidEndEditing:notification];
}

@end
