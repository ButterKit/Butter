//
//  BTRAppDelegate.m
//  BTRSplitViewDemo
//
//  Created by Robert Widmann on 12/8/12.
//  Copyright (c) 2012 CodaFi. All rights reserved.
//

#import "BTRAppDelegate.h"
#import <Butter/Butter.h>

@interface BTRAppDelegate () <NSSplitViewDelegate>
@property (nonatomic) IBOutlet BTRView *firstView;
@property (nonatomic) IBOutlet BTRView *secondView;
@property (nonatomic) IBOutlet BTRView *thirdView;
@property (nonatomic) IBOutlet BTRView *fourthView;
@end

@implementation BTRAppDelegate

-(void)awakeFromNib {
	[self.splitView setDividerDrawRectBlock:^(BTRSplitView *splitview, CGContextRef ctx, CGRect rect, NSUInteger index) {
		switch (index) {
			case 0:
				[[NSColor purpleColor] set];
				break;
			case 1:
				[[NSColor redColor] set];
				break;
			case 2:
				[[NSColor yellowColor] set];
				break;
			default:
				[[NSColor greenColor] set];
				break;
		}
		
		NSRectFill(rect);
	}];
	
	self.firstView.backgroundColor = [NSColor colorWithCalibratedWhite:0.9 alpha:1.000];
	self.secondView.backgroundColor = [NSColor colorWithCalibratedWhite:0.7 alpha:1.000];
	self.thirdView.backgroundColor = [NSColor colorWithCalibratedWhite:0.5 alpha:1.000];
	self.fourthView.backgroundColor = [NSColor colorWithCalibratedWhite:0.3 alpha:1.000];
}

-(IBAction)animateFirstDivider:(id)sender {
	[self.splitView setPosition:0 ofDividerAtIndex:0 animated:YES];
}

-(IBAction)animateSecondDivider:(id)sender {
	[self.splitView setPosition:0 ofDividerAtIndex:1 animated:YES];
}

-(IBAction)animateThirdDivider:(id)sender {
	[self.splitView setPosition:0 ofDividerAtIndex:2 animated:YES];
}

@end
