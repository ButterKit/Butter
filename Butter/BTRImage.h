//
//  BTRImage.h
//  Butter
//
//  Created by Jonathan Willing on 7/16/13.
//  Copyright (c) 2013 ButterKit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BTRImage : NSImage

// The edge insets for use in BTRImageView. This property will not affect normal image drawing.
@property (nonatomic, assign) NSEdgeInsets btr_capInsets;

// Returns an image created by calling NSImage +imageNamed:, copying the image, and setting `capInsets`.
+ (instancetype)resizableImageNamed:(NSString *)name withCapInsets:(NSEdgeInsets)insets;

@end
