//
//  BTRGeometryAdditions.h
//  BasicExample
//
//  Created by Indragie Karunaratne on 2012-12-07.
//  Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//

#import <Foundation/Foundation.h>

// Reimplementation of UIEdgeInsets

#define BTRNSEdgeInsetsZero (NSEdgeInsets){0, 0, 0, 0}

NS_INLINE CGRect BTRNSEdgeInsetsInsetRect(CGRect rect, NSEdgeInsets insets) {
	CGRect newRect = rect;
	newRect.origin.x += insets.left;
	newRect.size.width -= insets.right + insets.left;
	newRect.origin.y += insets.top;
	newRect.size.height -= insets.top + insets.bottom;
	return newRect;
}

// NSString to Data type conversions

NS_INLINE NSString* BTRNSStringFromCGRect(CGRect rect) {
    return NSStringFromRect(rect);
}

NS_INLINE NSString* BTRNSStringFromCGSize(CGSize size) {
    return NSStringFromSize(size);
}