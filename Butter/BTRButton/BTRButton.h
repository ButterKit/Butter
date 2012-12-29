//
//  BTRButton.h
//  Butter
//
//  Created by Jonathan Willing on 12/21/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import "BTRControl.h"
#import "BTRImageView.h"
#import "BTRLabel.h"

@interface BTRButton : BTRControl

- (NSImage *)backgroundImageForControlState:(BTRControlState)state;
- (void)setBackgroundImage:(NSImage *)image forControlState:(BTRControlState)state;

- (NSString *)titleForControlState:(BTRControlState)state;
- (void)setTitle:(NSString *)title forControlState:(BTRControlState)state;

- (NSAttributedString *)attributedTitleForState:(BTRControlState)state;
- (void)setAttributedTitle:(NSAttributedString *)title forState:(BTRControlState)state;

- (NSColor *)titleColorForState:(BTRControlState)state;
- (void)setTitleColor:(NSColor *)color forState:(BTRControlState)state;

- (NSShadow *)titleShadowForState:(BTRControlState)state;
- (void)setTitleShadow:(NSShadow *)shadow forState:(BTRControlState)state;

- (NSFont *)titleFontForState:(BTRControlState)state;
- (void)setTitleFont:(NSFont *)font forState:(BTRControlState)state;

@property (nonatomic, strong, readonly) NSString *currentTitle;
@property (nonatomic, strong, readonly) NSAttributedString *currentAttributedTitle;
@property (nonatomic, strong, readonly) NSImage *currentBackgroundImage;
@property (nonatomic, strong, readonly) NSColor *currentTitleColor;
@property (nonatomic, strong, readonly) NSShadow *currentTitleShadow;
@property (nonatomic, strong, readonly) NSFont *currentTitleFont;

// Modifies the contentMode on the underlying image view.
@property (nonatomic, assign) BTRViewContentMode contentMode;
@property (nonatomic, strong, readonly) BTRLabel *titleLabel;
@property (nonatomic, strong, readonly) BTRImageView *imageView;
@end
