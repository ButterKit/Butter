//
//  BTRImageView.m
//  Butter
//
//  Created by Jonathan Willing on 12/12/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import "BTRImageView.h"

@implementation BTRImageView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self == nil) return nil;
	[self initializeLayer];
    
    return self;
}

- (id)initWithImage:(NSImage *)image {
	self = [super initWithFrame:CGRectZero];
	if (self == nil) return nil;
	
	self.image = image;
	[self initializeLayer];
	
	return self;
}

- (void)initializeLayer {
	self.layer = [CALayer layer];
	self.wantsLayer = YES;
	//self.layer.contentsGravity = kCAGravityResizeAspect;
	self.layer.masksToBounds = YES;
	self.layer.actions = @{ @"contents": [NSNull null], @"onOrderIn": [NSNull null] };
}

- (void)setImage:(NSImage *)image {
	_image = image;
	self.layer.contents = image;
}

@end
