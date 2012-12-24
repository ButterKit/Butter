//
//  BTRControl.h
//  Butter
//
//  Created by Jonathan Willing on 12/14/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.

// This class is heavily inspired by UIKit and TwUI.
#import <Butter/Butter.h>

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
	BTRControlStateSelected		= 1 << 2
};

@interface BTRControl : BTRView

- (void)addBlock:(void (^)(BTRControlEvents events))block forControlEvents:(BTRControlEvents)events;

@property (nonatomic, readonly) NSInteger clickCount;

// TODO: These are not implemented properly
@property (nonatomic, readonly) BTRControlState state;
@property (nonatomic, getter = isEnabled) BOOL enabled;
@property (nonatomic, getter = isSelected) BOOL selected;
@property (nonatomic, getter = isHighlighted) BOOL highlighted;

@end
