//
//  Cell.m
//  SelectionDemo
//
//  Created by Jonathan Willing on 12/12/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import "Cell.h"
#import <Butter/NSView+BTRAdditions.h>

@implementation Cell

const CGFloat borderOffset = 10.f;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self == nil) return nil;
	
	[self addSubview:self.imageView];
	[self addSubview:self.label];
	
	BTRView *selectedBackgroundView = [[BTRView alloc] initWithFrame:self.bounds];
	selectedBackgroundView.backgroundColor = [NSColor redColor];
	selectedBackgroundView.opaque = YES;
	self.selectedBackgroundView = selectedBackgroundView;
	self.backgroundColor = [NSColor clearColor];
	
    return self;
}

- (NSTextField *)label {
	if (!_label) {
		_label = [[NSTextField alloc] initWithFrame:CGRectInset(self.bounds, borderOffset, borderOffset)];
		[_label setBezeled:NO];
		[_label setDrawsBackground:NO];
		[_label setEditable:NO];
		[_label setAlignment:NSCenterTextAlignment];
		[_label setSelectable:NO];
	}
	return _label;
}

- (BTRImageView *)imageView {
	if (!_imageView) {
		_imageView = [[BTRImageView alloc] initWithFrame:CGRectInset(self.bounds, borderOffset, borderOffset)];
	}
	return _imageView;
}
@end
