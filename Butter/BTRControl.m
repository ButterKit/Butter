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
@property (nonatomic, strong) NSMutableDictionary *content;

@property (nonatomic, readwrite) NSInteger clickCount;
@property (nonatomic) BOOL needsTrackingArea;
@property (nonatomic) BOOL mouseInside;
@property (nonatomic) BOOL mouseDown;
@property (nonatomic) BOOL mouseHover;

- (void)handleStateChange;
@end

@interface BTRControlContent ()
@property (nonatomic, assign) BTRControlState state;
@property (nonatomic, weak) BTRControl *control;
@end

@implementation BTRControlAction
@end

@implementation BTRControl

- (void)commonInitForBTRControl {
	self.enabled = YES;
	//TODO: If this isn't enabled, then subclasses might not get mouse events
	// when they need them if they don't add event handlers. Figure out a better
	// way to detect whether we need it or not. Alternatively, always use it?
	self.needsTrackingArea = YES;
	self.actions = [NSMutableArray array];
	self.content = [NSMutableDictionary dictionary];
}

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self == nil) return nil;
	[self commonInitForBTRControl];
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self == nil) return nil;
	[self commonInitForBTRControl];
	return self;
}

#pragma mark - Public API

+ (Class)controlContentClass {
	return [BTRControlContent class];
}

- (BTRControlContent *)contentForControlState:(BTRControlState)state {
	Class contentClass = [self.class controlContentClass];
	id content = self.content[@(state)];
	if (!content) {
		content = [contentClass new];
		[(BTRControlContent *)content setState:state];
		[(BTRControlContent *)content setControl:self];
		self.content[@(state)] = content;
	}
	return content;
}

#pragma mark - Convenience Methods

- (NSImage *)backgroundImageForControlState:(BTRControlState)state {
	return [self contentForControlState:state].backgroundImage;
}

- (void)setBackgroundImage:(NSImage *)image forControlState:(BTRControlState)state {
	[self contentForControlState:state].backgroundImage = image;
}

- (NSString *)titleForControlState:(BTRControlState)state {
	return [self contentForControlState:state].title;
}

- (void)setTitle:(NSString *)title forControlState:(BTRControlState)state {
	[self contentForControlState:state].title = title;
}

- (NSAttributedString *)attributedTitleForControlState:(BTRControlState)state {
	return [self contentForControlState:state].attributedTitle;
}

- (void)setAttributedTitle:(NSAttributedString *)title forControlState:(BTRControlState)state {
	[self contentForControlState:state].attributedTitle = title;
}

- (NSColor *)titleColorForControlState:(BTRControlState)state {
	return [self contentForControlState:state].titleColor;
}

- (void)setTitleColor:(NSColor *)color forControlState:(BTRControlState)state {
	[self contentForControlState:state].titleColor = color;
}

- (NSShadow *)titleShadowForControlState:(BTRControlState)state {
	return [self contentForControlState:state].titleShadow;
}

- (void)setTitleShadow:(NSShadow *)shadow forControlState:(BTRControlState)state {
	[self contentForControlState:state].titleShadow = shadow;
}

- (NSFont *)titleFontForControlState:(BTRControlState)state {
	return [self contentForControlState:state].titleFont;
}

- (void)setTitleFont:(NSFont *)font forControlState:(BTRControlState)state {
	[self contentForControlState:state].titleFont = font;
}

- (NSString *)currentTitle {
	return [self contentForControlState:self.state].title ?: [self contentForControlState:BTRControlStateNormal].title;
}

- (NSAttributedString *)currentAttributedTitle {
	return [self contentForControlState:self.state].attributedTitle ?: [self contentForControlState:BTRControlStateNormal].attributedTitle;
}

- (NSImage *)currentBackgroundImage {
	return [self contentForControlState:self.state].backgroundImage ?: [self contentForControlState:BTRControlStateNormal].backgroundImage;
}

- (NSColor *)currentTitleColor {
	return [self contentForControlState:self.state].titleColor ?: [self contentForControlState:BTRControlStateNormal].titleColor;
}

- (NSShadow *)currentTitleShadow {
	return [self contentForControlState:self.state].titleShadow ?: [self contentForControlState:BTRControlStateNormal].titleShadow;
}

- (NSFont *)currentTitleFont {
	return [self contentForControlState:self.state].titleFont ?: [self contentForControlState:BTRControlStateNormal].titleFont;
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

- (void)addTarget:(id)target action:(SEL)selector forControlEvents:(BTRControlEvents)events {
	BTRControlAction *action = [BTRControlAction new];
	action.target = target;
	action.action = selector;
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
	
	// This solution comes from <http://stackoverflow.com/a/9107224/153112>
	// Apparently if the mouse is already inside the view when the tracking
	// area is created, mouseEntered: is never called. This remedies that issue.
	NSPoint mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
    mouseLocation = [self convertPoint:mouseLocation fromView:nil];
	if (NSPointInRect(mouseLocation, self.bounds)) {
		[self mouseEntered: nil];
	} else {
		[self mouseExited: nil];
	}
	[self addTrackingArea:self.trackingArea];
	[super updateTrackingAreas];
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
}

- (void)mouseExited:(NSEvent *)event {
	[super mouseExited:event];
	self.mouseInside = NO;
	self.mouseHover = NO;
	[self sendActionsForControlEvents:BTRControlEventMouseExited];
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
				[NSApp sendAction:action.action to:action.target from:self];
			}
		}
	}
}

@end

@implementation BTRControlContent {
	NSMutableAttributedString *_attributedTitle;
}
@synthesize attributedTitle = _attributedTitle;

- (void)setBackgroundImage:(NSImage *)backgroundImage {
	if (_backgroundImage != backgroundImage) {
		_backgroundImage = backgroundImage;
		[self controlContentChanged];
	}
}

- (NSString *)title {
	return [self.attributedTitle string];
}

- (void)setTitle:(NSString *)title {
	NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
	style.alignment = NSCenterTextAlignment;
	style.lineBreakMode = NSLineBreakByTruncatingTail;
	NSMutableDictionary *attributes = [self.class defaultTitleAttributes].mutableCopy;
	if (self.titleColor) attributes[NSForegroundColorAttributeName] = self.titleColor;
	if (self.titleShadow) attributes[NSShadowAttributeName] = self.titleShadow;
	if (self.titleFont) attributes[NSFontAttributeName] = self.titleFont;
	self.attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attributes];
}

- (void)setAttributedTitle:(NSAttributedString *)attributedTitle {
	_attributedTitle = [attributedTitle mutableCopy];
	[self controlContentChanged];
}

- (void)setTitleColor:(NSColor *)titleColor {
	if (titleColor) {
		[_attributedTitle addAttribute:NSForegroundColorAttributeName value:titleColor range:[self entireStringRange]];
	} else {
		[_attributedTitle removeAttribute:NSForegroundColorAttributeName range:[self entireStringRange]];
	}
	_titleColor = titleColor;
	[self controlContentChanged];
}

- (void)setTitleShadow:(NSShadow *)titleShadow {
	if (titleShadow) {
		[_attributedTitle addAttribute:NSShadowAttributeName value:titleShadow range:[self entireStringRange]];
	} else {
		[_attributedTitle removeAttribute:NSShadowAttributeName range:[self entireStringRange]];
	}
	_titleShadow = titleShadow;
	[self controlContentChanged];
}

- (void)setTitleFont:(NSFont *)titleFont {
	if (titleFont) {
		[_attributedTitle addAttribute:NSFontAttributeName value:titleFont range:[self entireStringRange]];
	} else {
		[_attributedTitle removeAttribute:NSFontAttributeName range:[self entireStringRange]];
	}
	_titleFont = titleFont;
	[self controlContentChanged];
}

- (NSRange)entireStringRange {
	return NSMakeRange(0, [_attributedTitle length]);
}

+ (NSDictionary *)defaultTitleAttributes {
	NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
	style.alignment = NSCenterTextAlignment;
	style.lineBreakMode = NSLineBreakByTruncatingTail;
	return @{NSParagraphStyleAttributeName: style};
}

- (void)controlContentChanged {
	if ((self.control.state & self.state) == self.state) {
		[self.control handleStateChange];
	}
}
@end

