//
//  NSView+BTRLayoutAdditions.m
//  Butter
//
//  Created by Indragie Karunaratne on 8/6/2013.
//  Copyright (c) 2013 ButterKit. All rights reserved.
//

#import "NSView+BTRLayoutAdditions.h"

@implementation NSView (BTRLayoutAdditions)

- (void)btr_layout {
	[self resizeSubviewsWithOldSize:self.bounds.size];
}

@end
