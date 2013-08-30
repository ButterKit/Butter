//
//  BTRImageView.m
//  Butter
//
//  Created by Jonathan Willing on 12/12/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import "BTRImageView.h"
#import "BTRGeometryAdditions.h"
#import "BTRImage.h"

@interface BTRImageView()
@property (nonatomic, strong, readwrite) CALayer *imageLayer;
@end

@implementation BTRImageView {
	NSUInteger _currentImageFrame;
	NSUInteger _totalImageFrames;
	NSInteger _animationLoopCount;
	NSInteger _currentLoopCount;
	NSTimer *_animationTimer;
}

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame layerHosted:YES];
	if (self == nil) return nil;
	[self commonInit];
	return self;
}

- (id)initWithImage:(NSImage *)image {
	self = [super initWithFrame:(CGRect){ .size = image.size } layerHosted:YES];
	if (self == nil) return nil;
	self.image = image;
	[self commonInit];
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self == nil) return nil;
	self.layer = [CALayer layer];
	self.wantsLayer = YES;
	[self commonInit];
	return self;
}

- (void)commonInit {	
	self.imageLayer = [CALayer layer];
	self.imageLayer.delegate = self;
	self.imageLayer.masksToBounds = YES;
	[self.layer addSublayer:self.imageLayer];
	
	self.contentMode = BTRViewContentModeScaleToFill;
	self.imageLayer.anchorPoint = CGPointMake(0.5f, 0.5f);
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
	if (layer == self.layer) {
		self.imageLayer.frame = self.bounds;
	}
}

- (void)setImage:(NSImage *)image {
	if (_image == image)
		return;
	[_animationTimer invalidate];
	_animationTimer = nil;
	_image = image;
	self.imageLayer.contents = image;
	
	if ([image isKindOfClass:BTRImage.class]) {
		NSSize imageSize = image.size;
		NSEdgeInsets insets = ((BTRImage *)image).capInsets;
		self.imageLayer.contentsCenter = BTRCAContentsCenterForInsets(insets, imageSize);
	} else {
		self.imageLayer.contentsCenter = CGRectMake(0.0, 0.0, 1.0, 1.0);
	}
		
	NSArray *representations = [image representations];
	if (representations.count && self.animatesMultipleFrames) {
		NSBitmapImageRep *rep = representations[0];
		if ([rep isKindOfClass:[NSBitmapImageRep class]]) {
			_totalImageFrames = [[rep valueForProperty:NSImageFrameCount] unsignedIntegerValue];
			_currentImageFrame = [[rep valueForProperty:NSImageCurrentFrame] unsignedIntegerValue];
			_animationLoopCount = [[rep valueForProperty:NSImageLoopCount] unsignedIntegerValue];
			_currentLoopCount = 0;
			if (_totalImageFrames > 1) [self imageAnimationTimerFired:nil];
		}
	}	
}

- (void)imageAnimationTimerFired:(NSTimer *)timer {
	if (timer) _currentImageFrame++;
	if (_currentImageFrame > _totalImageFrames - 1) {
		_currentImageFrame = 0;
		_currentLoopCount++;
		if (_animationLoopCount != 0 && _currentLoopCount > _animationLoopCount) return;
	}
	NSBitmapImageRep *rep = self.image.representations[0];
	[rep setProperty:NSImageCurrentFrame withValue:@(_currentImageFrame)];
	if (!NSEqualRects(self.visibleRect, NSZeroRect)) {
		NSImage *currentFrameImage = [NSImage new];
		[currentFrameImage addRepresentation:rep];
		self.imageLayer.contents = currentFrameImage;
	}
	_animationTimer = [NSTimer scheduledTimerWithTimeInterval:[[rep valueForProperty:NSImageCurrentFrameDuration] doubleValue] target:self selector:@selector(imageAnimationTimerFired:) userInfo:nil repeats:NO];
}

- (void)viewDidChangeBackingProperties {
	self.layer.contentsScale = self.window.backingScaleFactor;
	self.imageLayer.contentsScale = self.layer.contentsScale;
}

#pragma mark Layer properties

- (void)setCornerRadius:(CGFloat)cornerRadius {
	self.imageLayer.cornerRadius = cornerRadius;
}

- (CGFloat)cornerRadius {
	return self.imageLayer.cornerRadius;
}

- (void)setTransform:(CATransform3D)transform {
	self.imageLayer.transform = transform;
}

- (CATransform3D)transform {
	return self.imageLayer.transform;
}

- (void)addAnimation:(CAAnimation *)animation forKey:(NSString *)key {
	[self.imageLayer addAnimation:animation forKey:key];
}

#pragma mark Content mode

- (void)setContentMode:(BTRViewContentMode)contentMode {
	_contentMode = contentMode;
	self.imageLayer.contentsGravity = [self contentsGravityFromContentMode:contentMode];
}

- (NSString *)contentsGravityFromContentMode:(BTRViewContentMode)contentMode {
	switch (contentMode) {
		case BTRViewContentModeScaleToFill:
			return kCAGravityResize;
			break;
		case BTRViewContentModeScaleAspectFit:
			return kCAGravityResizeAspect;
			break;
		case BTRViewContentModeScaleAspectFill:
			return kCAGravityResizeAspectFill;
			break;
		case BTRViewContentModeCenter:
			return kCAGravityCenter;
			break;
		case BTRViewContentModeTop:
			return kCAGravityTop;
			break;
		case BTRViewContentModeBottom:
			return kCAGravityBottom;
			break;
		case BTRViewContentModeLeft:
			return kCAGravityLeft;
			break;
		case BTRViewContentModeRight:
			return kCAGravityRight;
			break;
		case BTRViewContentModeTopLeft:
			return kCAGravityTopLeft;
			break;
		case BTRViewContentModeTopRight:
			return kCAGravityTopRight;
			break;
		case BTRViewContentModeBottomLeft:
			return kCAGravityBottomLeft;
			break;
		case BTRViewContentModeBottomRight:
			return kCAGravityBottomRight;
			break;
		default:
			break;
	}
}

@end
