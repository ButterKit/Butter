//
//	Originally from RBLClipView
//
//  Created by Justin Spahr-Summers on 2012-09-14.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "BTRCollectionViewClipView.h"
#import <QuartzCore/QuartzCore.h>

@implementation BTRCollectionViewClipView

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self == nil) return nil;
	
	self.layer = [CAScrollLayer layer];
	self.wantsLayer = YES;
	
	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawNever;
	
	// Matches default NSClipView settings.
	self.backgroundColor = NSColor.clearColor;
	
	return self;
}

@end
