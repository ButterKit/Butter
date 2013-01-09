//
//  BTRControl.h
//  Butter
//
//  Created by Jonathan Willing on 12/14/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.

// This class is heavily inspired by UIKit and TwUI.
#import <Butter/BTRView.h>

typedef NS_OPTIONS(NSUInteger, BTRControlEvents) {
	// TODO: UNIMPLEMENTED
	// ***************
	BTRControlEventMouseDragEnter		= 1 << 1,
	BTRControlEventMouseDragExit		= 1 << 2,
	// ***************
	
	BTRControlEventMouseUpInside		= 1 << 3,
	BTRControlEventMouseDownInside		= 1 << 4,
	BTRControlEventMouseUpOutside		= 1 << 5,
	BTRControlEventMouseEntered			= 1 << 6,
	BTRControlEventMouseExited			= 1 << 7,
	
	BTRControlEventClick				= 1 << 12, //after mouse down & up inside
	BTRControlEventClickRepeat			= 1 << 13,
	BTRControlEventLeftClick			= 1 << 14,
	BTRControlEventRightClick			= 1 << 15,
	
	BTRControlEventValueChanged			= 1 << 16, // sliders, etc.
};

typedef NS_OPTIONS(NSUInteger, BTRControlState) {
	BTRControlStateNormal		= 0,
	BTRControlStateHighlighted	= 1 << 0,
	BTRControlStateDisabled		= 1 << 1,
	BTRControlStateSelected		= 1 << 2,
	BTRControlStateHover		= 1 << 3
};

@class BTRControlContent;
@interface BTRControl : BTRView

- (void)addBlock:(void (^)(BTRControlEvents events))block forControlEvents:(BTRControlEvents)events;

@property (nonatomic, readonly) NSInteger clickCount;

@property (nonatomic, readonly) BTRControlState state;
@property (nonatomic, getter = isEnabled) BOOL enabled;
// TODO: Selected is not implemented.
@property (nonatomic, getter = isSelected) BOOL selected;
@property (nonatomic, getter = isHighlighted) BOOL highlighted;

// Implemented by subclasses. Useful for reacting to state changes caused either by
// mouse events, or by changing the state properties above.
- (void)handleStateChange;

// This method should be called by subclasses
- (void)sendActionsForControlEvents:(BTRControlEvents)events;

// Implemented by subclasses. Use it to return a subclass of BTRControlContent that
// contains additional content properties pertaining to the specific control.
+ (Class)controlContentClass;

// Returns the content (BTRControlContent or a subclass, if one was
// returned from +controlContentClass) for the given control state.
// A new content object will be created if one does not exist
- (BTRControlContent *)contentForControlState:(BTRControlState)state;

// General properties for controls
// Your control subclass can add more methods and properties similar to this
@property (nonatomic, strong, readonly) NSString *currentTitle;
@property (nonatomic, strong, readonly) NSAttributedString *currentAttributedTitle;
@property (nonatomic, strong, readonly) NSImage *currentBackgroundImage;
@property (nonatomic, strong, readonly) NSColor *currentTitleColor;
@property (nonatomic, strong, readonly) NSShadow *currentTitleShadow;
@property (nonatomic, strong, readonly) NSFont *currentTitleFont;

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

@end

@interface BTRControlContent : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSAttributedString *attributedTitle;
@property (nonatomic, strong) NSColor *titleColor;
@property (nonatomic, strong) NSShadow *titleShadow;
@property (nonatomic, strong) NSFont *titleFont;
@property (nonatomic, strong) NSImage *backgroundImage;
// Any setter on a BTRControlContent subclass should always call the
// -controlContentChanged method in order to notify the control of the
// change. TODO: See if there is a way to monitor all properties for
// change so that each setter individually doesn't need to call the method
- (void)controlContentChanged;

// Subclasses can use this to return text attributes that the
// attributedTitle should use by default
+ (NSDictionary *)defaultTitleAttributes;
@end

#pragma mark - Private Interface

@interface BTRControlAction : NSObject
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;
@property (nonatomic, copy) void(^block)(BTRControlEvents events);
@property (nonatomic, assign) BTRControlEvents events;
@end
