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

@end

@implementation BTRAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
}

-(void)awakeFromNib {
	[self.splitView setDividerDrawBlock:^(BTRSplitView *splitview, CGContextRef ctx, CGRect rect, NSUInteger index) {
		switch (index) {
			case 0:
				[[NSColor redColor]set];
				break;
			case 1:
				[[NSColor orangeColor]set];
				break;
			case 2:
				[[NSColor yellowColor]set];
				break;
			default:
				[[NSColor greenColor]set];
				break;
		}
		NSRectFill(rect);
	}];
}

-(IBAction)animateFirstDivider:(id)sender {
	[self.splitView setPosition:100 ofDividerAtIndex:0 animated:YES];
}

-(IBAction)animateSecondDivider:(id)sender {
	[self.splitView setPosition:200 ofDividerAtIndex:1 animated:YES];
}

-(IBAction)animateThirdDivider:(id)sender {
	[self.splitView setPosition:300 ofDividerAtIndex:2 animated:YES];
}

@end
