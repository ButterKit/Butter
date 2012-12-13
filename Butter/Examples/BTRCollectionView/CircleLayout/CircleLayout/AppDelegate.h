//
//  AppDelegate.h
//  CircleLayout
//
//  Created by Jonathan Willing on 12/7/12.
//  Copyright (c) 2012 Jonathan Willing. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Butter/Butter.h>
#import "Cell.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, BTRCollectionViewDataSource, BTRCollectionViewDelegate, CellDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSButton *toggleButton;

- (IBAction)changeLayout:(id)sender;
- (IBAction)addCell:(id)sender;

@end
