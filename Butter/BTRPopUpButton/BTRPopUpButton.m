//
//  BTRPopUpButton.m
//  Butter
//
//  Created by Indragie Karunaratne on 2012-12-30.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import "BTRPopUpButton.h"

@interface BTRPopUpButtonLabel : BTRLabel
@end
@interface BTRPopUpButtonImageView : BTRImageView
@end

@interface BTRPopUpButtonContent : BTRControlContent
@property (nonatomic, strong) NSImage *arrowImage;
@end

static CGFloat const BTRPopUpButtonElementSpacing = 5.f;

@implementation BTRPopUpButton

#pragma mark - Initialization

- (void)commonInitForBTRPopUpButton
{
	_label = [[BTRPopUpButtonLabel alloc] initWithFrame:NSZeroRect];
	_imageView = [[BTRPopUpButtonImageView alloc] initWithFrame:NSZeroRect];
	_imageView.contentMode = BTRViewContentModeCenter;
	_arrowImageView = [[BTRPopUpButtonImageView alloc] initWithFrame:NSZeroRect];
	_arrowImageView.contentMode = BTRViewContentModeCenter;
}

- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self == nil) return nil;
	[self commonInitForBTRPopUpButton];
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self == nil) return nil;
	[self commonInitForBTRPopUpButton];
	return self;
}

#pragma mark - BTRControl

+ (Class)controlContentClass {
	return [BTRPopUpButtonContent class];
}

- (BTRPopUpButtonContent *)popUpButtonContentForState:(BTRControlState)state {
	return (BTRPopUpButtonContent *)[self contentForControlState:state];
}

- (void)handleStateChange
{
	self.label.attributedStringValue = self.currentAttributedTitle;
	self.arrowImageView.image = self.currentArrowImage;
	self.imageView.image = self.currentBackgroundImage;
}

#pragma mark - Public Methods

- (NSImage *)arrowImageForControlState:(BTRControlState)state {
	return [self popUpButtonContentForState:state].arrowImage;
}

- (void)setArrowImage:(NSImage *)image forControlState:(BTRControlState)state {
	[self popUpButtonContentForState:state].arrowImage = image;
}

- (NSImage *)currentArrowImage {
	return [self popUpButtonContentForState:self.state].arrowImage ?: [self popUpButtonContentForState:BTRControlStateNormal].arrowImage;
}

#pragma mark - NSView

- (void)layout {
	[super layout];
	NSRect imageFrame, titleFrame, arrowFrame;
	NSDivideRect(self.bounds, &imageFrame, &titleFrame, self.currentBackgroundImage.size.width, NSMinXEdge);
	titleFrame.origin.x += BTRPopUpButtonElementSpacing;
	titleFrame.size.width -= BTRPopUpButtonElementSpacing;
	NSDivideRect(titleFrame, &arrowFrame, &titleFrame, self.currentArrowImage.size.width, NSMaxXEdge);
	titleFrame.size.width -= BTRPopUpButtonElementSpacing;
	self.imageView.frame = imageFrame;
	self.label.frame = titleFrame;
	self.arrowImageView.frame = arrowFrame;
}

#pragma mark - Mouse Events

- (void)mouseDown:(NSEvent *)theEvent {
	[super mouseDown:theEvent];
	if (self.menu)
		[NSMenu popUpContextMenu:self.menu withEvent:theEvent forView:self];
}
@end

@implementation BTRPopUpButtonContent
- (void)setArrowImage:(NSImage *)arrowImage
{
	if (_arrowImage != arrowImage) {
		_arrowImage = arrowImage;
		[self controlContentChanged];
	}
}
@end

// Prevent the subviews from receiving mouse events
@implementation BTRPopUpButtonLabel
- (NSView *)hitTest:(NSPoint)aPoint { return nil; }
@end

@implementation BTRPopUpButtonImageView
- (NSView *)hitTest:(NSPoint)aPoint { return nil; }
@end