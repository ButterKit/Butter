//
//  BTRPopUpButton.m
//  Butter
//
//  Created by Indragie Karunaratne on 2012-12-30.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import "BTRPopUpButton.h"

@interface BTRPopUpButtonLabel : BTRLabel
@end
@interface BTRPopUpButtonImageView : BTRImageView
@end

@interface BTRPopUpButtonContent : BTRControlContent
@property (nonatomic, strong) NSImage *arrowImage;
@end

@implementation BTRPopUpButton

#pragma mark - Initialization

- (void)commonInitForBTRPopUpButton
{
	_label = [[BTRPopUpButtonLabel alloc] initWithFrame:NSZeroRect];
	//_label.layer.backgroundColor = [NSColor blueColor].CGColor;
	_imageView = [[BTRPopUpButtonImageView alloc] initWithFrame:NSZeroRect];
	_imageView.contentMode = BTRViewContentModeCenter;
	//_imageView.layer.backgroundColor = [NSColor redColor].CGColor;
	_arrowImageView = [[BTRPopUpButtonImageView alloc] initWithFrame:NSZeroRect];
	_arrowImageView.contentMode = BTRViewContentModeCenter;
	_backgroundImageView = [[BTRPopUpButtonImageView alloc] initWithFrame:NSZeroRect];
	self.layer.masksToBounds = YES;
	[self addSubview:_backgroundImageView];
	[self addSubview:_imageView];
	[self addSubview:_label];
	[self addSubview:_arrowImageView];
}

- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self == nil) return nil;
	[self commonInitForBTRPopUpButton];
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self == nil) return nil;
	[self commonInitForBTRPopUpButton];
	return self;
}

#pragma mark - BTRControl

+ (Class)controlContentClass {
	return [BTRPopUpButtonContent class];
}

- (BTRPopUpButtonContent *)popUpButtonContentForState:(BTRControlState)state {
	return (BTRPopUpButtonContent *)[self contentForControlState:state];
}

- (void)handleStateChange {
	NSString *title = self.selectedItem.title;
	if (title) {
		NSMutableDictionary *textAttributes = [BTRPopUpButtonContent defaultTitleAttributes].mutableCopy;
		NSColor *textColor = self.currentTitleColor;
		NSShadow *textShadow = self.currentTitleShadow;
		NSFont *textFont = self.currentTitleFont;
		if (textColor) textAttributes[NSForegroundColorAttributeName] = textColor;
		if (textShadow) textAttributes[NSShadowAttributeName] = textShadow;
		if (textFont) textAttributes[NSFontAttributeName] = textFont;
		self.label.attributedStringValue = [[NSAttributedString alloc] initWithString:title attributes:textAttributes];
	} else {
		self.label.attributedStringValue = nil;
	}
	self.arrowImageView.image = self.currentArrowImage;
	self.backgroundImageView.image = self.currentBackgroundImage;
	self.imageView.image = self.selectedItem.image;
}

#pragma mark - Public Methods

- (NSImage *)arrowImageForControlState:(BTRControlState)state {
	return [self popUpButtonContentForState:state].arrowImage;
}

- (void)setArrowImage:(NSImage *)image forControlState:(BTRControlState)state {
	[self popUpButtonContentForState:state].arrowImage = image;
}

- (NSImage *)currentArrowImage {
	return [self popUpButtonContentForState:self.state].arrowImage ?: [self popUpButtonContentForState:BTRControlStateNormal].arrowImage;
}

- (void)selectItemAtIndex:(NSUInteger)index {
	self.selectedItem = [self.menu itemAtIndex:index];
}

- (NSUInteger)indexOfSelectedItem {
	return [self.menu indexOfItem:self.selectedItem];
}

#pragma mark - Accessors

- (void)setMenu:(NSMenu *)menu {
	if (_menu != menu) {
		self.selectedItem = nil;
		_menu = [menu copy];
		_menu.autoenablesItems = YES;
		[_menu.itemArray enumerateObjectsUsingBlock:^(NSMenuItem *item, NSUInteger idx, BOOL *stop) {
			item.target = self;
			item.action = @selector(popUpMenuSelectedItem:);
		}];
		if ([menu numberOfItems]) {
			self.selectedItem = [menu itemAtIndex:0];
			self.selectedItem.state = NSOnState;
		}
	}
}

- (void)setSelectedItem:(NSMenuItem *)selectedItem {
	if (_selectedItem != selectedItem) {
		_selectedItem.state = NSOffState;
		_selectedItem = selectedItem;
		_selectedItem.state = NSOnState;
		[self handleStateChange];
		[self setNeedsLayout:YES];
	}
}

#pragma mark - NSView

- (void)layout {
	self.imageView.frame = [self imageFrame];
	self.label.frame = [self labelFrame];
	self.arrowImageView.frame = [self arrowFrame];
	self.backgroundImageView.frame = self.bounds;
	[super layout];
}

- (NSRect)imageFrame {
	return NSMakeRect([self edgeInset], 0.f, self.selectedItem.image.size.width, NSHeight(self.bounds));
}

- (NSRect)labelFrame {
	NSRect imageFrame = [self imageFrame];
	NSRect arrowFrame = [self arrowFrame];
	CGFloat xOrigin = NSMaxX(imageFrame) + [self interElementSpacing];
	return NSMakeRect(xOrigin, 0.f, NSMinX(arrowFrame) - xOrigin - [self interElementSpacing], NSHeight(self.bounds));
}

- (NSRect)arrowFrame {
	CGFloat arrowWidth = self.currentArrowImage.size.width;
	return NSMakeRect(NSMaxX(self.bounds) - arrowWidth - [self edgeInset], 0.f, arrowWidth, NSHeight(self.bounds));
}

- (CGFloat)interElementSpacing {
	return 3.f;
}

- (CGFloat)edgeInset {
	return 6.f;
}

- (CGFloat)widthToFit {
	return  self.selectedItem.image.size.width + self.label.attributedStringValue.size.width + self.currentArrowImage.size.width + (2.f * [self edgeInset]) + (2.f * [self interElementSpacing]);
}

- (void)sizeToFit {
	NSRect newFrame = self.frame;
	newFrame.size.width = [self widthToFit];
	self.frame = newFrame;
}

#pragma mark - Mouse Events

- (void)mouseDown:(NSEvent *)theEvent {
	[super mouseDown:theEvent];
	if (self.menu) {
		NSPoint location = [self convertPoint:self.bounds.origin toView:nil];
		NSEvent *synthesizedEvent = [NSEvent mouseEventWithType:theEvent.type location:location modifierFlags:theEvent.modifierFlags timestamp:theEvent.timestamp windowNumber:theEvent.windowNumber context:theEvent.context eventNumber:theEvent.eventNumber clickCount:theEvent.clickCount pressure:theEvent.pressure];
		[NSMenu popUpContextMenu:self.menu withEvent:synthesizedEvent forView:self];
	}
}

#pragma mark - Menu Events

- (IBAction)popUpMenuSelectedItem:(id)sender {
	self.selectedItem = sender;
	[self sendActionsForControlEvents:BTRControlEventValueChanged];
	[self handleStateChange];
	// When the menu closes, neither mouseUp or mouseEntered are called.
	// Call them manually to display the proper state
	[self mouseUp:nil];
	[self mouseExited:nil];
}
@end

@implementation BTRPopUpButtonContent
- (void)setArrowImage:(NSImage *)arrowImage {
	if (_arrowImage != arrowImage) {
		_arrowImage = arrowImage;
		[self controlContentChanged];
	}
}

+ (NSDictionary *)defaultTitleAttributes {
	NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
	style.lineBreakMode = NSLineBreakByTruncatingTail;
	return @{NSParagraphStyleAttributeName: style};
}
@end

// Prevent the subviews from receiving mouse events
@implementation BTRPopUpButtonLabel
- (NSView *)hitTest:(NSPoint)aPoint { return nil; }
@end

@implementation BTRPopUpButtonImageView
- (NSView *)hitTest:(NSPoint)aPoint { return nil; }
@end