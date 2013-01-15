//
//  AppDelegate.h
//  ImageView Test
//
//  Created by Jonathan Willing on 1/14/13.
//  Copyright (c) 2013 Butter. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Butter/Butter.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, assign) IBOutlet BTRImageView *imageView;

@end
