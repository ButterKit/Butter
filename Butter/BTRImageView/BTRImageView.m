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
	self = [super initWithFrame:frame layerHosted:YES];
	if (self == nil) return nil;
	[self commonInit];
	return self;
}

- (id)initWithImage:(NSImage *)image {
	self = [super initWithFrame:CGRectZero layerHosted:YES];
	if (self == nil) return nil;
	self.image = image;
	[self commonInit];
	return self;
}

- (void)commonInit {
	//self.layer.contentsGravity = kCAGravityResizeAspect;
	self.layer.masksToBounds = YES;
	//self.layer.actions = @{ @"contents": [NSNull null], @"onOrderIn": [NSNull null] };
}

// Let super (BTRView) handle the contents, in case -animtesContents is set to YES.
// Otherwise we don't want any animations on our layer.
- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event {
	if ([event isEqualToString:@"contents"])
		return [super actionForLayer:layer forKey:event];
	
	return (id<CAAction>)[NSNull null];
}

- (void)setImage:(NSImage *)image {
	if (_image == image)
		return;
	_image = image;
	self.layer.contents = image;
}

@end
