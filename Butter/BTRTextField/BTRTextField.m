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

@interface BTRTextFieldCell : NSTextFieldCell
@end

const CGFloat BTRTextFieldCornerRadius = 3.f;
const CGFloat BTRTextFieldInnerRadius = 2.f;

@implementation BTRTextField {
	BOOL _btrDrawsBackground;
}

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
	
	// Copy over *all* the attributes to the new cell
	// There really is no other easy way to do this :(
	NSTextFieldCell *oldCell = self.cell;
	BTRTextFieldCell *newCell = [[BTRTextFieldCell alloc] initTextCell:self.stringValue];
	newCell.placeholderString = oldCell.placeholderString;
	newCell.textColor = oldCell.textColor;
	newCell.font = oldCell.font;
	newCell.alignment = oldCell.alignment;
	newCell.lineBreakMode = oldCell.lineBreakMode;
	newCell.truncatesLastVisibleLine = oldCell.truncatesLastVisibleLine;
	newCell.wraps = oldCell.wraps;
	newCell.baseWritingDirection = oldCell.baseWritingDirection;
	newCell.attributedStringValue = oldCell.attributedStringValue;
	newCell.allowsEditingTextAttributes = oldCell.allowsEditingTextAttributes;
	newCell.action = oldCell.action;
	newCell.target = oldCell.target;
	newCell.focusRingType = oldCell.focusRingType;
	[newCell setEditable:[oldCell isEditable]];
	[newCell setSelectable:[oldCell isSelectable]];
	self.cell = newCell;
	
	self.focusRingType = NSFocusRingTypeNone;
	super.drawsBackground = NO;
	self.drawsBackground = YES;
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

+ (Class)cellClass
{
	return [BTRTextFieldCell class];
}

#pragma mark - Accessors

- (void)setDrawsBackground:(BOOL)flag
{
	if (_btrDrawsBackground != flag) {
		_btrDrawsBackground = flag;
		[self setNeedsDisplay:YES];
	}
}

- (BOOL)drawsBackground
{
	return _btrDrawsBackground;
}

#pragma mark Drawing

- (void)drawRect:(NSRect)dirtyRect {
	if (!self.drawsBackground) {
		[super drawRect:dirtyRect];
		return;
	}
	[[NSColor colorWithDeviceWhite:1.f alpha:0.6f] set];
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

#pragma mark - Bounds

- (NSRect)drawingRectForBounds:(NSRect)theRect
{
	return NSInsetRect(theRect, 2.f, 0.f);
}

@end

// Originally written by Daniel Jalkut as RSVerticallyCenteredTextFieldCell
// Licensed under MIT
// <http://www.red-sweater.com/blog/148/what-a-difference-a-cell-makes>
@implementation BTRTextFieldCell {
	BOOL _isEditingOrSelecting;
}

- (NSRect)drawingRectForBounds:(NSRect)theRect
{
	// Get the parent's idea of where we should draw
	NSRect newRect = [super drawingRectForBounds:theRect];
	
	// When the text field is being
	// edited or selected, we have to turn off the magic because it screws up
	// the configuration of the field editor.  We sneak around this by
	// intercepting selectWithFrame and editWithFrame and sneaking a
	// reduced, centered rect in at the last minute.
	if (_isEditingOrSelecting == NO)
	{
		// Get our ideal size for current text
		NSSize textSize = [self cellSizeForBounds:theRect];
		
		// Center that in the proposed rect
		float heightDelta = newRect.size.height - textSize.height;
		if (heightDelta > 0)
		{
			newRect.size.height -= heightDelta;
			newRect.origin.y += (heightDelta / 2);
		}
	}
	
	return newRect;
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
	aRect = [self drawingRectForBounds:aRect];
	_isEditingOrSelecting = YES;
	[super selectWithFrame:aRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
	_isEditingOrSelecting = NO;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
	aRect = [self drawingRectForBounds:aRect];
	_isEditingOrSelecting = YES;
	[super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
	_isEditingOrSelecting = NO;
}

@end
