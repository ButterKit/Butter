//
//  AppDelegate.m
//  Popup Button Demo
//
//  Created by Jonathan Willing on 12/30/12.
//  Copyright (c) 2012 Butter. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)awakeFromNib {
	[self.popupButton setArrowImage:[NSImage imageNamed:NSImageNameLeftFacingTriangleTemplate] forControlState:BTRControlStateNormal];
}

@end
