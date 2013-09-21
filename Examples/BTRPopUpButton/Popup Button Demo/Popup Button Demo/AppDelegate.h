//
//  AppDelegate.h
//  Popup Button Demo
//
//  Created by Jonathan Willing on 12/30/12.
//  Copyright (c) 2012 Butter. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Butter/Butter.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet BTRPopUpButton *popupButton;

@end
