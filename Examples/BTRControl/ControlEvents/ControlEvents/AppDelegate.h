//
//  AppDelegate.h
//  ControlEvents
//
//  Created by Jonathan Willing on 12/14/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Butter/Butter.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet BTRControl *control;

@end
