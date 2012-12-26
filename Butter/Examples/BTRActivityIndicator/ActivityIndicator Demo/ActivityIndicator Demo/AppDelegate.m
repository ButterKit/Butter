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
	
	[self.activityIndicator startAnimating];
	self.activityIndicator.layer.shadowOpacity = 1.f;
	self.activityIndicator.layer.shadowColor = NSColor.whiteColor.CGColor;
	self.activityIndicator.layer.shadowRadius = 0.f;
	self.activityIndicator.layer.shadowOffset = CGSizeMake(0, -1);
	
	
	double delayInSeconds = 2.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		// Uncomment for testing.
		
		//self.activityIndicator.progressShapeColor = [NSColor blueColor];
		//self.activityIndicator.progressAnimationDuration = 3.f;
		//self.activityIndicator.progressShapeLength = 30.f;
		//self.activityIndicator.progressShapeSpread = 20.f;
		//self.activityIndicator.progressShapeThickness = 9.f;
		
		//CALayer *testLayer = [CALayer layer];
		//testLayer.cornerRadius = 5.f;
		//testLayer.bounds = CGRectMake(0, 0, 10, 10);
		//testLayer.backgroundColor = NSColor.grayColor.CGColor;
		//self.activityIndicator.progressShapeLayer = testLayer;
	});
	
	double d = 5;
	dispatch_time_t p = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(d * NSEC_PER_SEC));
	dispatch_after(p, dispatch_get_main_queue(), ^(void){
		[self.activityIndicator stopAnimating];
	});
}

@end
