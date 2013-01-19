//
//  BTRButton.m
//  Butter
//
//  Created by Jonathan Willing on 12/21/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import "BTRButton.h"
#import "BTRLabel.h"

// Subclasses to override -hitTest: and prevent them from receiving mouse events
@interface BTRButtonLabel : BTRLabel
@end

@interface BTRButtonImageView : BTRImageView
@end

@implementation BTRButton

#pragma mark - Initialization

- (void)commonInitForBTRButton {
	_imageView = [[BTRButtonImageView alloc] initWithFrame:self.bounds];
	[self addSubview:_imageView];
	_titleLabel = [[BTRButtonLabel alloc] initWithFrame:self.bounds];
	[self addSubview:_titleLabel];
}

- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self == nil) return nil;
	[self commonInitForBTRButton];
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self == nil) return nil;
	[self commonInitForBTRButton];
	return self;
}

#pragma mark State

- (void)handleStateChange {
	self.titleLabel.attributedStringValue = self.currentAttributedTitle;
	
	NSImage *backgroundImage = self.currentBackgroundImage;
	if (backgroundImage == nil) {
		// If we can't find a control state for the current state, we to the normal control state image.
		// If the normal state image can't be found, revert back to the default image for the current state.
		backgroundImage = [self defaultBackgroundImageForControlState:self.state];
	}
	self.imageView.image = backgroundImage;
}

#pragma mark Drawing

- (void)layout {
	self.imageView.frame = [self imageFrame];
	self.titleLabel.frame = [self labelFrame];
	[super layout];
}

- (void)setContentMode:(BTRViewContentMode)contentMode {
	self.imageView.contentMode = contentMode;
}

- (BTRViewContentMode)contentMode {
	return self.imageView.contentMode;
}

// TODO: Ideally we'll have a good default style that can be drawn here.
- (NSImage *)defaultBackgroundImageForControlState:(BTRControlState)state {
	return [NSImage imageWithSize:self.bounds.size flipped:NO drawingHandler:^BOOL(NSRect rect) {
		
		if (state == BTRControlStateNormal) {
			[NSColor.redColor set];
		} else if (state & BTRControlStateHighlighted) {
			[NSColor.blueColor set];
		}
		
		NSRectFill(rect);
		
		return YES;
	}];
}

// When a button is clicked, the initial state change shouldn't animate
// or it will appear to be laggy. However, if the user has opted to animate
// the contents, we animate the transition back out.
- (void)setHighlighted:(BOOL)highlighted {
	self.imageView.animatesContents = (!highlighted && self.animatesContents);
	[super setHighlighted:highlighted];
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
	[super setCornerRadius:cornerRadius];
	self.imageView.cornerRadius = cornerRadius;
}

- (CGFloat)cornerRadius {
	return self.imageView.cornerRadius;
}

#pragma mark - Subclassing Hooks

- (CGRect)imageFrame {
	return self.bounds;
}

- (CGRect)labelFrame {
	return self.bounds;
}
@end

@implementation BTRButtonLabel
- (NSView *)hitTest:(NSPoint)aPoint { return nil; }
@end

@implementation BTRButtonImageView
- (NSView *)hitTest:(NSPoint)aPoint { return nil; }
@end
