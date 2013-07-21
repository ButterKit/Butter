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
	[self.button setTitle:@"Selected" forControlState:BTRControlStateSelected];
	[self.button setTitle:@"Selected & Hover" forControlState:BTRControlStateSelected | BTRControlStateHover];
	
	NSImage *green = [self pixelImageWithColor:NSColor.greenColor];
	NSImage *purple = [self pixelImageWithColor:NSColor.purpleColor];
	NSImage *red = [self pixelImageWithColor:NSColor.redColor];
	NSImage *yellow = [self pixelImageWithColor:NSColor.yellowColor];
	NSImage *blue = [self pixelImageWithColor:NSColor.blueColor];
	
	[self.button setBackgroundImage:green forControlState:BTRControlStateNormal];
	[self.button setBackgroundImage:red forControlState:BTRControlStateHighlighted];
	[self.button setBackgroundImage:purple forControlState:BTRControlStateHover];
	[self.button setBackgroundImage:yellow forControlState:BTRControlStateSelected];
	[self.button setBackgroundImage:blue forControlState:BTRControlStateSelected | BTRControlStateHover];

	// fades the image back after clicking down
	self.button.animatesContents = YES;
	
	// you can either use the traditional target/action approach
	[self.button addTarget:self action:@selector(buttonClicked:) forControlEvents:BTRControlEventClick];
	
	// or you can use fancy blocks.
	[self.button addBlock:^(BTRControlEvents events) {
		NSLog(@"repeated click");
	} forControlEvents:BTRControlEventClickRepeat];
}

- (void)buttonClicked:(BTRButton *)sender {
	// toggle the selected state of the button each click
	sender.selected = !sender.selected;
}

- (NSImage *)pixelImageWithColor:(NSColor *)color {
	return [NSImage imageWithSize:CGSizeMake(1, 1) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
		[color set];
		NSRectFill(dstRect);
		return YES;
	}];
}

@end
