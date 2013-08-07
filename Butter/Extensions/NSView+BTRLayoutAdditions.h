//
//  NSView+BTRLayoutAdditions.h
//  Butter
//
//  Created by Indragie Karunaratne on 8/6/2013.
//  Copyright (c) 2013 ButterKit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSView (BTRLayoutAdditions)

// Equivalent to calling -resizeSubviewsWithOldSize: with the current
// bounds size. Used in place of -setNeedsLayout:, which is only applicable
// for constraints based layout.
- (void)btr_layout;

@end
