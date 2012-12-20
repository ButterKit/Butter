//
//  BTRAppDelegate.h
//  BTRSplitViewDemo
//
//  Created by Robert Widmann on 12/8/12.
//  Copyright (c) 2012 CodaFi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BTRSplitView;

@interface BTRAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet BTRSplitView *splitView;

-(IBAction)animateFirstDivider:(id)sender;
-(IBAction)animateSecondDivider:(id)sender;
-(IBAction)animateThirdDivider:(id)sender;

@end
