//
//  Cell.m
//  SelectionDemo
//
//  Created by Jonathan Willing on 12/12/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import "Cell.h"
#import <Butter/NSView+RBLAnimationAdditions.h>

@implementation Cell

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self == nil) return nil;
	
	[self addSubview:self.imageView];
	[self addSubview:self.label];
	
	RBLView *selectedBackgroundView = [[RBLView alloc] initWithFrame:self.bounds];
	selectedBackgroundView.backgroundColor = [NSColor redColor];
	selectedBackgroundView.opaque = YES;
	self.selectedBackgroundView = selectedBackgroundView;
	self.backgroundColor = [NSColor clearColor];
	
    return self;
}

- (NSTextField *)label {
	if (!_label) {
		_label = [[NSTextField alloc] initWithFrame:self.bounds];
		[_label setBezeled:NO];
		[_label setDrawsBackground:NO];
		[_label setEditable:NO];
		[_label setAlignment:NSCenterTextAlignment];
		[_label setSelectable:NO];
		[_label.layer setOpaque:YES];
	}
	return _label;
}

- (BTRImageView *)imageView {
	if (!_imageView) {
		_imageView = [[BTRImageView alloc] initWithFrame:self.bounds];
	}
	return _imageView;
}

// It is very easy to animate the highlighting animation.
- (void)setHighlighted:(BOOL)highlighted {
	[NSView rbl_animateWithDuration:0.3 animations:^{
		[super setHighlighted:highlighted];
	} completion:NULL];
}

@end
