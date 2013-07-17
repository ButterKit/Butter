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
	[self.button setTitle:@"Hovering" forControlState:BTRControlStateHover];
	
	NSImage *green = [self pixelImageWithColor:NSColor.greenColor];
	NSImage *purple = [self pixelImageWithColor:NSColor.purpleColor];
	NSImage *red = [self pixelImageWithColor:NSColor.redColor];
	
	[self.button setBackgroundImage:green forControlState:BTRControlStateNormal];
	[self.button setBackgroundImage:red forControlState:BTRControlStateHighlighted];
	[self.button setBackgroundImage:purple forControlState:BTRControlStateHover];
	
	[self.button addBlock:^(BTRControlEvents events) {
		NSLog(@"clicked!");
	} forControlEvents:BTRControlEventClick];
	
	// fades the image back after clicking down
	self.button.animatesContents = YES;
}

- (NSImage *)pixelImageWithColor:(NSColor *)color {
	return [NSImage imageWithSize:CGSizeMake(1, 1) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
		[color set];
		NSRectFill(dstRect);
		return YES;
	}];
}

@end
