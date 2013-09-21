//
//  AppDelegate.m
//  ImageView Test
//
//  Created by Jonathan Willing on 1/14/13.
//  Copyright (c) 2013 Butter. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)awakeFromNib {
	self.imageView.contentMode = BTRViewContentModeCenter;
	
	// We're just setting the image view's image to a random image. In this case I'm redrawing
	// system-provided artwork at a larger size, just for demonstration purposes.
	self.imageView.image = [NSImage imageWithSize:CGSizeMake(150, 150) flipped:NO
								   drawingHandler:^BOOL(NSRect dstRect) {
									   [[NSImage imageNamed:NSImageNameUser] drawInRect:dstRect fromRect:CGRectZero operation:NSCompositeSourceOver fraction:1];
									   return YES;
								   }];
}

- (void)imageViewContentModeShouldChange:(NSSegmentedControl *)sender {
	self.imageView.contentMode = (sender.selectedSegment == 0 ? BTRViewContentModeCenter : BTRViewContentModeScaleAspectFit);
}

@end
