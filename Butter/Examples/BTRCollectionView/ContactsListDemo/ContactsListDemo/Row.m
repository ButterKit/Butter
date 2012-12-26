//
//  Row.m
//  ContactsListDemo
//
//  Created by Indragie Karunaratne on 2012-12-25.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import "Row.h"

#define kBorderColor [NSColor colorWithDeviceRed:0.73 green:0.73 blue:0.73 alpha:1.0]

@implementation Row

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect bottomBorderRect = NSMakeRect(0.f, 0.f, NSWidth(self.bounds), 1.f);
	[kBorderColor set];
	NSRectFill(bottomBorderRect);
}

@end
