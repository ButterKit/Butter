//
//  BTRAppDelegate.m
//  ScrollView-Test
//
//  Created by Zach Waldowski on 7/20/13.
//  Copyright (c) 2013 ButterKit. All rights reserved.
//

#import "BTRAppDelegate.h"
#import "BTRNameGenerator.h"

#define ARC4RANDOM_MAX 0x100000000LL
#define RANDF(min,max) (((double)arc4random() / ARC4RANDOM_MAX) * (max-min) + min)

@implementation BTRAppDelegate

- (NSDate *)randomDate
{
	NSTimeInterval randomInterval = RANDF(0, [NSDate timeIntervalSinceReferenceDate]);
	return [NSDate dateWithTimeIntervalSinceReferenceDate:randomInterval];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:10000];
	for (NSUInteger i = 0; i < 10000; i++) {
		[array addObject:@{
			@"name": [[BTRNameGenerator sharedGenerator] getName],
			@"date": [self randomDate]
		}];
	}
	self.objects = array;
}

@end
