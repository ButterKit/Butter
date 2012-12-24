//
//  BTRImageView.m
//  Butter
//
//  Created by Jonathan Willing on 12/12/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import "BTRImageView.h"

@interface BTRImageView()
@property (nonatomic, strong) CALayer *imageLayer;
@end

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
	
	self.imageLayer = [CALayer layer];
	self.imageLayer.delegate = self;
	[self.layer addSublayer:self.imageLayer];
}

- (void)layout {
	[super layout];
	self.imageLayer.frame = self.bounds;
}

// Let super (BTRView) handle the contents, in case -animtesContents is set to YES.
// Otherwise we don't want any animations on our layer.
- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event {
	if ([event isEqualToString:@"contents"] && layer == self.imageLayer) {
		return [super actionForLayer:layer forKey:event];
	}
	
	return (id<CAAction>)[NSNull null];
}

- (void)setImage:(NSImage *)image {
	if (_image == image)
		return;
	_image = image;
	self.imageLayer.contents = image;
}

@end
