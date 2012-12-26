//
//  BTRControl.m
//  Butter
//
//  Created by Jonathan Willing on 12/14/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//  Portions of code inspired by TwUI.

#import "BTRControl.h"

@interface BTRControl()
@property (nonatomic, strong) NSMutableArray *actions;
@property (nonatomic, strong) NSTrackingArea *trackingArea;

@property (nonatomic, readwrite) NSInteger clickCount;
@property (nonatomic) BOOL needsTrackingArea;
@property (nonatomic) BOOL mouseInside;
@property (nonatomic) BOOL mouseDown;
@property (nonatomic) BOOL mouseHover;

- (void)handleStateChange;
@end

@interface BTRControlAction : NSObject
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;
@property (nonatomic, copy) void(^block)(BTRControlEvents events);
@property (nonatomic, assign) BTRControlEvents events;
@end

@implementation BTRControlAction
@end

@implementation BTRControl

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self == nil) return nil;
	self.enabled = YES;
	//TODO: If this isn't enabled, then subclasses might not get mouse events
	// when they need them if they don't add event handlers. Figure out a better
	// way to detect whether we need it or not. Alternatively, always use it?
	self.needsTrackingArea = YES;
	return self;
}

- (NSMutableArray *)actions {
	if (!_actions) {
		_actions = [@[] mutableCopy];
	}
	return _actions;
}


#pragma mark State

- (BTRControlState)state {
	BTRControlState state = BTRControlStateNormal;
	if (self.highlighted) state |= BTRControlStateHighlighted;
	if (self.selected) state |= BTRControlStateSelected;
	if (!self.enabled) state |= BTRControlStateDisabled;
	if (self.mouseHover && !self.highlighted) state |= BTRControlStateHover;
	return state;
}

- (void)setEnabled:(BOOL)enabled {
	[self updateStateWithOld:&_enabled new:enabled];
}

- (void)setSelected:(BOOL)selected {
	[self updateStateWithOld:&_selected new:selected];
}

- (void)setHighlighted:(BOOL)highlighted {
	[self updateStateWithOld:&_highlighted new:highlighted];
}

- (void)setMouseHover:(BOOL)mouseHover {
	[self updateStateWithOld:&_mouseHover new:mouseHover];
}

- (void)updateStateWithOld:(BOOL *)old new:(BOOL)new {
	BOOL o = *old;
	*old = new;
	if (o != new) {
		[self handleStateChange];
	}
}

- (void)handleStateChange {
	// Implemented by subclasses
}

- (void)addBlock:(void (^)(BTRControlEvents))block forControlEvents:(BTRControlEvents)events {
	NSParameterAssert(block);
	BTRControlAction *action = [BTRControlAction new];
	action.block = block;
	action.events = events;
	[self.actions addObject:action];
	[self handleUpdatedEvents:events];
}

- (void)handleUpdatedEvents:(BTRControlEvents)events {
	// TODO: Verify if we need a tracking area here.
	self.needsTrackingArea = YES;
}

- (void)updateTrackingAreas {
	if (!self.needsTrackingArea)
		return;

	if (self.trackingArea) {
		[self removeTrackingArea:self.trackingArea];
		self.trackingArea = nil;
	}
	
	// TODO: Figure out correct tracking to implement mouse drag
	NSUInteger options = (NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingEnabledDuringMouseDrag);
	self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
													 options:options
													   owner:self userInfo:nil];
	[self addTrackingArea:self.trackingArea];
}

- (void)setNeedsTrackingArea:(BOOL)needsTrackingArea {
	_needsTrackingArea = needsTrackingArea;
	if (!needsTrackingArea && self.trackingArea != nil) {
		[self removeTrackingArea:self.trackingArea];
		self.trackingArea = nil;
	}
}

- (void)mouseDown:(NSEvent *)event {
	[super mouseDown:event];
	[self handleMouseDown:event];
}

- (void)mouseUp:(NSEvent *)event {
	[super mouseUp:event];
	[self handleMouseUp:event];
}

- (void)rightMouseUp:(NSEvent *)event {
	[super rightMouseUp:event];
	[self handleMouseUp:event];
}

- (void)rightMouseDown:(NSEvent *)event {
	[super rightMouseDown:event];
	[self handleMouseDown:event];
}

- (void)mouseEntered:(NSEvent *)event {
	[super mouseEntered:event];
	self.mouseInside = YES;
	self.mouseHover = YES;
	[self sendActionsForControlEvents:BTRControlEventMouseEntered];
	if (self.mouseDown)
		self.highlighted = YES;
}

- (void)mouseExited:(NSEvent *)event {
	[super mouseExited:event];
	self.mouseInside = NO;
	self.mouseHover = NO;
	[self sendActionsForControlEvents:BTRControlEventMouseExited];
	self.highlighted = NO;
}

//- (void)mouseDragged:(NSEvent *)theEvent {
//	[super mouseDragged:theEvent];
//		
//	if (self.mouseDown) {
//		BTRControlEvents events = 1;
//		
//		// TODO: Implement logic here
//		
//		//[self sendActionsForControlEvents:events];
//	}
//}

- (void)handleMouseDown:(NSEvent *)event {
	self.clickCount = event.clickCount;
	self.mouseDown = YES;
	
	BTRControlEvents events = 1;
	events |= BTRControlEventMouseDownInside;
	
	[self sendActionsForControlEvents:events];
	
	self.highlighted = YES;
}

- (void)handleMouseUp:(NSEvent *)event {
	self.mouseDown = NO;
	
	BTRControlEvents events = 1;
	if (self.clickCount > 1) {
		events |= BTRControlEventClickRepeat;
	}
	if (event.type == NSLeftMouseUp && self.mouseInside) {
		events |= BTRControlEventLeftClick;
	} else if (event.type == NSRightMouseUp && self.mouseInside) {
		events |= BTRControlEventRightClick;
	}
	if (self.mouseInside) {
		events |= BTRControlEventMouseUpInside;
		events |= BTRControlEventClick;
	} else {
		events |= BTRControlEventMouseUpOutside;
	}
	
	[self sendActionsForControlEvents:events];
	
	self.highlighted = NO;
}

- (void)sendActionsForControlEvents:(BTRControlEvents)events {
	for (BTRControlAction *action in self.actions) {
		if (action.events & events) {
			if (action.block != nil) {
				action.block(events);
			} else if (action.action != nil) { // the target can be nil
				[NSApp sendAction:action.action to:action.target];
			}
		}
	}
}

@end
