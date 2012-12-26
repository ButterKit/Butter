//
//  AppDelegate.h
//  ActivityIndicator Demo
//
//  Created by Jonathan Willing on 12/26/12.
//  Copyright (c) 2012 Butter. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Butter/BTRActivityIndicator.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, assign) IBOutlet NSWindow *window;
@property (nonatomic, assign) IBOutlet BTRActivityIndicator *activityIndicator;

@end
