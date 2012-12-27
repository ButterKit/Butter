//
//  AppDelegate.m
//  ActivityIndicator Demo
//
//  Created by Jonathan Willing on 12/26/12.
//  Copyright (c) 2012 Butter. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)awakeFromNib {
	self.window.backgroundColor = [NSColor colorWithCalibratedWhite:0.9 alpha:1];
	
	[self.defaultIndicator startAnimating];
	
	// Customize the first custom indicator.
	self.customizedIndicatorOne.progressShapeColor = [NSColor colorWithCalibratedRed:0.251 green:0.000 blue:0.502 alpha:1.000];
	self.customizedIndicatorOne.progressAnimationDuration = 1.5f;
	self.customizedIndicatorOne.progressShapeLength = 20.f;
	self.customizedIndicatorOne.progressShapeSpread = 8.f;
	self.customizedIndicatorOne.progressShapeCount = 20;
	self.customizedIndicatorOne.progressShapeThickness = 4.f;
	[self.customizedIndicatorOne startAnimating];

	
	// Create a custom indicator shape layer for the second custom indicator.
	CALayer *customIndicatorLayer = [CALayer layer];
	customIndicatorLayer.bounds = CGRectMake(0, 0, 6, 6);
	customIndicatorLayer.cornerRadius = CGRectGetWidth(customIndicatorLayer.bounds) / 2;
	customIndicatorLayer.backgroundColor = NSColor.grayColor.CGColor;
	
	// Add a layer shadow onto the progress indicator.
	self.customizedIndicatorTwo.layer.shadowColor = [NSColor colorWithCalibratedWhite:1.f alpha:0.5f].CGColor;
	self.customizedIndicatorTwo.layer.shadowRadius = 0.f;
	self.customizedIndicatorTwo.layer.shadowOpacity = 1.f;
	self.customizedIndicatorTwo.layer.shadowOffset = CGSizeMake(0, -1.f);
	
	// Now we actually set the customized shape layer as the progress shape layer, and start animating.
	self.customizedIndicatorTwo.progressShapeLayer = customIndicatorLayer;
	
	// Although we could have set the progress shape layer after beginning the animation, it
	// causes undesired artifacts as the animation must restart and the layer must be replicated.
	[self.customizedIndicatorTwo startAnimating];
}

- (void)toggleAnimation:(id)sender {
	if (self.customizedIndicatorTwo.animating) {
		[self.customizedIndicatorTwo stopAnimating];
	} else {
		[self.customizedIndicatorTwo startAnimating];
	}
}

@end
