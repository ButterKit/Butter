//
//  BTRImageView.m
//  Butter
//
//  Created by Jonathan Willing on 12/12/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import "BTRImageView.h"
#import "BTRGeometryAdditions.h"
#import "RBLResizableImage.h"

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

- (id)initWithCoder:(NSCoder *)aDecoder
{
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
}

- (void)layout {
	[super layout];
	self.imageLayer.frame = self.bounds;
}

// Let super (BTRView) handle the contents, in case -animtesContents is set to YES.
// Otherwise we don't want any animations on our layer.
/*- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event {
	if ([event isEqualToString:@"contents"] && layer == self.imageLayer) {
		return [super actionForLayer:layer forKey:event];
	}
	
	return (id<CAAction>)[NSNull null];
}*/

- (void)setImage:(NSImage *)image {
	if (_image == image)
		return;
	_image = image;
	self.imageLayer.contents = image;
	if ([image isKindOfClass:[RBLResizableImage class]]) {
		NSSize imageSize = image.size;
		NSEdgeInsets insets = [(RBLResizableImage *)image capInsets];
		CGRect imageRect = BTRNSEdgeInsetsInsetRect((CGRect){.size=imageSize}, insets);
		if (imageRect.size.width > 0) {
			imageRect.origin.x /= imageSize.width;
			imageRect.size.width /= imageSize.width;
		}
		if (imageRect.size.height > 0) {
			imageRect.origin.y /= imageSize.height;
			imageRect.size.height /= imageSize.height;
		}
		self.imageLayer.contentsCenter = imageRect;
	} else {
		self.imageLayer.contentsCenter = CGRectMake(0.0, 0.0, 1.0, 1.0);
	}
}


#pragma mark Layer properties

- (void)setCornerRadius:(CGFloat)cornerRadius {
	self.imageLayer.cornerRadius = cornerRadius;
}

- (CGFloat)cornerRadius {
	return self.imageLayer.cornerRadius;
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
