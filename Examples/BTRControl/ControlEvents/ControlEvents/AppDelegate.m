//
//  AppDelegate.m
//  ControlEvents
//
//  Created by Jonathan Willing on 12/14/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)awakeFromNib {
	self.control.backgroundColor = [NSColor redColor];
	
	[self.control addBlock:^(BTRControlEvents events) { NSLog(@"drag enter"); } forControlEvents:BTRControlEventMouseDragEnter];
	[self.control addBlock:^(BTRControlEvents events) { NSLog(@"drag exit"); } forControlEvents:BTRControlEventMouseDragExit];
	[self.control addBlock:^(BTRControlEvents events) { NSLog(@"mouse up inside"); } forControlEvents:BTRControlEventMouseUpInside];
	[self.control addBlock:^(BTRControlEvents events) { NSLog(@"mouse down inside"); } forControlEvents:BTRControlEventMouseDownInside];
	[self.control addBlock:^(BTRControlEvents events) { NSLog(@"mouse up outside"); } forControlEvents:BTRControlEventMouseUpOutside];
	[self.control addBlock:^(BTRControlEvents events) { NSLog(@"mouse entered"); } forControlEvents:BTRControlEventMouseEntered];
	[self.control addBlock:^(BTRControlEvents events) { NSLog(@"mouse exited"); } forControlEvents:BTRControlEventMouseExited];
	
	[self.control addBlock:^(BTRControlEvents events) { NSLog(@"click"); } forControlEvents:BTRControlEventClick];
	[self.control addBlock:^(BTRControlEvents events) { NSLog(@"repeat click"); } forControlEvents:BTRControlEventClickRepeat];
	[self.control addBlock:^(BTRControlEvents events) { NSLog(@"left click"); } forControlEvents:BTRControlEventLeftClick];
	[self.control addBlock:^(BTRControlEvents events) { NSLog(@"right click"); } forControlEvents:BTRControlEventRightClick];
	
	[self.control addBlock:^(BTRControlEvents events) { NSLog(@"***VALUE CHANGED***"); } forControlEvents:BTRControlEventValueChanged];

	self.control.enabled = YES;
	self.control.selected = YES;
	NSLog(@"state: %li",self.control.state);
	
	[self.control addTarget:self action:@selector(handleClick:) forControlEvents:BTRControlEventClick];
}

- (void)handleClick:(id)sender {
	NSLog(@"click (selector)");
}

@end
