//
//  AppDelegate.h
//  ButtonDemo
//
//  Created by Jonathan Willing on 12/21/12.
//  Copyright (c) 2012 Butter. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Butter/Butter.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, weak) IBOutlet BTRButton *button;

@end
