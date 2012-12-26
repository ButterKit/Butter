//
//  SectionHeader.m
//  ContactsListDemo
//
//  Created by Indragie Karunaratne on 2012-12-25.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import "SectionHeader.h"

#define kBorderColor [NSColor colorWithDeviceRed:0.73 green:0.73 blue:0.73 alpha:1.0]
#define kHighlightColor [NSColor colorWithDeviceWhite:1.f alpha:0.75f]
#define kBottomColor [NSColor colorWithDeviceRed:0.86 green:0.86 blue:0.86 alpha:1.0]
#define kTopColor [NSColor colorWithDeviceRed:0.93 green:0.93 blue:0.93 alpha:1.0]

@implementation SectionHeader

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect bottomBorderRect = NSMakeRect(0.f, 0.f, NSWidth(self.bounds), 1.f);
	NSRect topBorderRect = bottomBorderRect;
	topBorderRect.origin.y = NSMaxY(self.bounds) - 1.f;
	NSRect highlightRect = topBorderRect;
	highlightRect.origin.y -= 1.f;
	NSRect gradientRect = NSMakeRect(0.f, NSMaxY(bottomBorderRect), bottomBorderRect.size.width, NSMinY(highlightRect) - NSMaxY(bottomBorderRect));
	[kBorderColor set];
	NSRectFill(bottomBorderRect);
	NSRectFill(topBorderRect);
	[kHighlightColor set];
	[NSBezierPath fillRect:highlightRect];
	NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:kBottomColor endingColor:kTopColor];
	[gradient drawInRect:gradientRect angle:90.f];
}

@end
