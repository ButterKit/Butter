//
//  BTRGridLayoutItem.h
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne and Jonathan Willing. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BTRGridLayoutSection, BTRGridLayoutRow;

// Represents a single grid item; only created for non-uniform-sized grids.
@interface BTRGridLayoutItem : NSObject

@property (nonatomic, unsafe_unretained) BTRGridLayoutSection *section;
@property (nonatomic, unsafe_unretained) BTRGridLayoutRow *rowObject;
@property (nonatomic, assign) CGRect itemFrame;

@end
