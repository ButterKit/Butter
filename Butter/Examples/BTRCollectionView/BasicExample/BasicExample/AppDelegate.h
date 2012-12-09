//
//  AppDelegate.h
//  BasicExample
//
//  Created by Indragie Karunaratne on 2012-12-06.
//  Copyright (c) 2012 Indragie Karunaratne. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Butter/Butter.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, BTRCollectionViewDataSource, BTRCollectionViewDelegate>

@property (assign) IBOutlet NSWindow *window;

@end
