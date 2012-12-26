//
//  AppDelegate.h
//  ContactsListDemo
//
//  Created by Indragie Karunaratne on 2012-12-25.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Butter/Butter.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, weak) IBOutlet BTRCollectionView *collectionView;
@end
