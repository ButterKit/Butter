//
//  BTRScrollView.h
//  Originally from Rebel
//
//  Created by Jonathan Willing on 12/4/12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// A NSScrollView subclass which uses an instance of BTRClipView
// as the clip view instead of NSClipView.
//
// Layer-backed by default.
@interface BTRScrollView : NSScrollView

// Overridden by subviews to change the class of the clip view
+ (Class)clipViewClass;

// The distance that the content view is inset from the enclosing scroll view.
@property (nonatomic, assign) NSEdgeInsets contentInsets;

// The distance the scroll indicators are inset from the edge of the scroll view.
@property (nonatomic, assign) NSEdgeInsets scrollIndicatorInsets;

// The point at which the origin of the content view is offset from the origin of the scroll view.
@property (nonatomic, assign) NSPoint contentOffset;

@end
