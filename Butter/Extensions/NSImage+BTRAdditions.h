//
//  NSImage+BTRAdditions.h
//  Butter
//
//  Created by Jonathan Willing on 7/16/13.
//  Copyright (c) 2013 ButterKit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (BTRAdditions)

// The edge insets for use in BTRImageView. This property will not affect normal image drawing.
@property (nonatomic, assign) NSEdgeInsets btr_capInsets;

// Returns the wrapped value for the edge insets. This value will be nil if insets have not been set.
- (NSValue *)btr_capInsetsValue;

// Returns an image created by calling NSImage +imageNamed:, copying the image, and setting `btr_capInsets`
+ (instancetype)btr_resizableImageNamed:(NSString *)name withCapInsets:(NSEdgeInsets)insets;

// Returns a copy of the image with `btr_capInsets` set to the given value.
- (instancetype)btr_resizableImageWithCapInsets:(NSEdgeInsets)insets;
@end
