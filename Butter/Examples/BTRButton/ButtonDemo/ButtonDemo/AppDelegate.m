//
//  AppDelegate.m
//  ButtonDemo
//
//  Created by Jonathan Willing on 12/21/12.
//  Copyright (c) 2012 Butter. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)awakeFromNib {
	[self.button setTitle:@"Standard" forControlState:BTRControlStateNormal];
	[self.button setTitle:@"Highlighted" forControlState:BTRControlStateHighlighted];
	
	[self.button setBackgroundImage:[NSImage imageWithSize:CGSizeMake(1, 1) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
		[[NSColor greenColor] set];
		NSRectFill(dstRect);
		return YES;
	}] forControlState:BTRControlStateNormal];
	
	[self.button setBackgroundImage:[NSImage imageWithSize:CGSizeMake(1, 1) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
		[[NSColor redColor] set];
		NSRectFill(dstRect);
		return YES;
	}] forControlState:BTRControlStateHighlighted];
	
	self.button.animatesContents = YES;
}

@end
