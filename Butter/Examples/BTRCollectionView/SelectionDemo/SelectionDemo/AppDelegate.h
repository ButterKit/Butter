//
//  AppDelegate.h
//  SelectionDemo
//
//  Created by Jonathan Willing on 12/12/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Butter/Butter.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, BTRCollectionViewDataSource, BTRCollectionViewDelegate>

@property (assign) IBOutlet NSWindow *window;

@end
