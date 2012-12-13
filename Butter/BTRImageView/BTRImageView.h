//
//  BTRImageView.h
//  Butter
//
//  Created by Jonathan Willing on 12/12/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//typedef NS_ENUM(NSInteger, BTRViewContentMode) {

@interface BTRImageView : NSView

- (id)initWithImage:(NSImage *)image;

@property (nonatomic, strong) NSImage *image;

@end
