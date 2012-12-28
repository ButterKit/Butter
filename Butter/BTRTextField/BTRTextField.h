//
//  BTRTextField.h
//  Butter
//
//  Created by Jonathan Willing on 12/21/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BTRControl.h"
#import "BTRImageView.h"

// BTRTextField should *not* be layer backed in Interface Builder
// This leads to a bug that causes an additional shadow to be shown
// underneath the field
@interface BTRTextField : NSTextField
- (NSImage *)backgroundImageForControlState:(BTRControlState)state;
- (void)setBackgroundImage:(NSImage *)image forControlState:(BTRControlState)state;

// Modifies the contentMode on the underlying image view.
@property (nonatomic, assign) BTRViewContentMode contentMode;
@property (nonatomic, assign) BOOL animatesContents;

// Reimplementation of BTRControl API
@property (nonatomic, readonly) BTRControlState state;
@property (nonatomic, getter = isHighlighted) BOOL highlighted;
@property (nonatomic, readonly) NSInteger clickCount;

- (void)addBlock:(void (^)(BTRControlEvents events))block forControlEvents:(BTRControlEvents)events;
@end
