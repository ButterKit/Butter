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
}

@end
