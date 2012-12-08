//
//  BTRGeometryAdditions.h
//  BasicExample
//
//  Created by Indragie Karunaratne on 2012-12-07.
//  Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//

#import <Foundation/Foundation.h>

// Reimplementation of UIEdgeInsets

typedef struct {
    CGFloat top, left, bottom, right;
} BTREdgeInsets;

#define BTREdgeInsetsZero (BTREdgeInsets){0, 0, 0, 0}

NS_INLINE BTREdgeInsets BTREdgeInsetsMake(CGFloat top, CGFloat left, CGFloat bottom, CGFloat right) {
    return (BTREdgeInsets){top, left, bottom, right};
}

// NSString <-> Data type conversions

NS_INLINE NSString* BTRNSStringFromCGRect(CGRect rect) {
    return NSStringFromRect(rect);
}

NS_INLINE NSString* BTRNSStringFromCGSize(CGSize size) {
    return NSStringFromSize(size);
}