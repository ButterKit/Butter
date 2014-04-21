//
//  BTRTextFieldProtocol.h
//  Butter
//
//  Created by Aron Cedercrantz on 21/04/14.
//  Copyright (c) 2014 ButterKit. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BTRControl.h"
#import "BTRImageView.h"

// The BTRTextField protocol declares all methods a Butter text field responds
// to.
//
// Instead of this protocol you're probably more interested in the two concrete
// classes `BTRTextField` and `BTRSecureTextField`.
@protocol BTRTextField <NSObject>

- (NSImage *)backgroundImageForControlState:(BTRControlState)state;
- (void)setBackgroundImage:(NSImage *)image forControlState:(BTRControlState)state;

@property (nonatomic, assign) BOOL drawsFocusRing;
// Modifies the contentMode on the underlying image view.
@property (nonatomic, assign) BTRViewContentMode contentMode;
@property (nonatomic, assign) BOOL animatesContents;
@property (nonatomic, strong) NSTextFieldCell *textFieldCell;

// Text attribute accessors
@property (nonatomic, strong) NSString *placeholderTitle;
@property (nonatomic, strong) NSColor *placeholderTextColor;
@property (nonatomic, strong) NSFont *placeholderFont;
@property (nonatomic, strong) NSShadow *placeholderShadow;

@property (nonatomic, strong) NSShadow *textShadow;

// State
@property (nonatomic, readonly) BTRControlState state;
@property (nonatomic, getter = isHighlighted) BOOL highlighted;
@property (nonatomic, readonly) NSInteger clickCount;

- (void)addBlock:(void (^)(BTRControlEvents events))block forControlEvents:(BTRControlEvents)events;

@end
