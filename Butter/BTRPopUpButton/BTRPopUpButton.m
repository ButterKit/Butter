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

@implementation BTRPopUpButton

#pragma mark - Initialization

- (void)commonInitForBTRPopUpButton
{
	_label = [[BTRPopUpButtonLabel alloc] initWithFrame:NSZeroRect];
	_imageView = [[BTRPopUpButtonImageView alloc] initWithFrame:NSZeroRect];
	_arrowImageView = [[BTRPopUpButtonImageView alloc] initWithFrame:NSZeroRect];
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


#pragma mark - Public Methods

- (NSImage *)arrowImageForControlState:(BTRControlState)state {
	
}

- (void)setArrowImage:(NSImage *)image forControlState:(BTRControlState)state {
	
}

@end

// Prevent the subviews from receiving mouse events
@implementation BTRPopUpButtonLabel
- (NSView *)hitTest:(NSPoint)aPoint { return nil; }
@end

@implementation BTRPopUpButtonImageView
- (NSView *)hitTest:(NSPoint)aPoint { return nil; }
@end