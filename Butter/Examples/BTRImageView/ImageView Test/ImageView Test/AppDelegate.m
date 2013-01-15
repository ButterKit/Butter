//
//  AppDelegate.m
//  ImageView Test
//
//  Created by Jonathan Willing on 1/14/13.
//  Copyright (c) 2013 Butter. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
}

- (void)awakeFromNib {
	self.imageView.image = [NSImage imageNamed:NSImageNameSlideshowTemplate];
}

@end
