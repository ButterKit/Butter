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

@interface BTRPopUpButton ()
@property (nonatomic, strong) BTRImageView *imageView;
@property (nonatomic, strong) BTRLabel *label;

@property (nonatomic, strong) BTRImageView *backgroundImageView;
@property (nonatomic, strong) BTRImageView *arrowImageView;
@end

@interface BTRPopUpButtonContent : BTRControlContent
@property (nonatomic, strong) NSImage *arrowImage;
@end

@implementation BTRPopUpButton

#pragma mark - Initialization

- (void)commonInitForBTRPopUpButton
{
	self.label = [[BTRPopUpButtonLabel alloc] initWithFrame:NSZeroRect];
	self.imageView = [[BTRPopUpButtonImageView alloc] initWithFrame:NSZeroRect];
	self.imageView.contentMode = BTRViewContentModeCenter;
	self.arrowImageView = [[BTRPopUpButtonImageView alloc] initWithFrame:NSZeroRect];
	self.arrowImageView.contentMode = BTRViewContentModeCenter;
	self.backgroundImageView = [[BTRPopUpButtonImageView alloc] initWithFrame:NSZeroRect];
	
	self.layer.masksToBounds = YES;
	[self addSubview:self.backgroundImageView];
	[self addSubview:self.imageView];
	[self addSubview:self.label];
	[self addSubview:self.arrowImageView];
	
	// Observe changes to the menu's delegate. When the delegate changes
	// we want to force a menu refresh if the delegate has implemented the
	// menu update methods declared in the NSMenuDelegate protocol.
	[self addObserver:self forKeyPath:@"menu.delegate" options:NSKeyValueObservingOptionNew context:NULL];
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

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"menu.delegate"];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	// Force a menu update when the delegate changes
	if ([keyPath isEqualToString:@"menu.delegate"]) {
		[self forceMenuUpdate];
	}
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
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc removeObserver:self name:NSMenuDidEndTrackingNotification object:_menu];
		self.selectedItem = nil;
		_menu = menu;
		if (_menu) {
			_menu.autoenablesItems = self.autoenablesItems;
			// Register for notifications for when the menu closes. This is important
			// because mouseUp: and mouseExited: are not normally called if the menu is closed
			// when the cursor is outside the pop up button. This ensures that the proper
			// state is restored once the menu is closed.
			[nc addObserverForName:NSMenuDidEndTrackingNotification object:_menu queue:nil usingBlock:^(NSNotification *note) {
				[self mouseUp:nil];
				[self mouseExited:nil];
			}];
			// Force a menu update from the delegate once the menu is initially set
			[self forceMenuUpdate];
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

- (void)reconfigureMenuItems
{
	// Reset the target and action of each item so that the pop up button receives
	// the events when the items are clicked.
	[self.menu.itemArray enumerateObjectsUsingBlock:^(NSMenuItem *item, NSUInteger idx, BOOL *stop) {
		item.target = self;
		item.action = @selector(popUpMenuSelectedItem:);
	}];
	// Default to setting the first item in the menu as the selected item
	if ([self.menu numberOfItems] && !self.selectedItem) {
		self.selectedItem = [self.menu itemAtIndex:0];
		self.selectedItem.state = NSOnState;
	}
}

- (void)forceMenuUpdate
{
	id delegate = self.menu.delegate;
	if (!delegate) {
		[self reconfigureMenuItems];
		return;
	}
	// This runs a delegate based update to the menu as documented by the NSMenuDelegate protocol.
	// First a check to see if -menuNeedsUpdate: is implemented. If so, this means that the delegate
	// takes complete control of handling the update in this one method, and no further
	// method calls are necessary
	if ([delegate respondsToSelector:@selector(menuNeedsUpdate:)]) {
		[delegate menuNeedsUpdate:self.menu];
	// The other update mechanism that the delegate provides are two "data source" type methods that
	// are called repetitively to update each item
	} else if ([delegate respondsToSelector:@selector(numberOfItemsInMenu:)] && [delegate respondsToSelector:@selector(menu:updateItem:atIndex:shouldCancel:)]) {
		NSInteger numberOfItems = [delegate numberOfItemsInMenu:self.menu];
		BOOL shouldCancel = NO;
		for (NSInteger i = 0; i < numberOfItems; i++) {
			shouldCancel = [delegate menu:self.menu updateItem:[self.menu itemAtIndex:i] atIndex:i shouldCancel:shouldCancel];
		}
	}
	[self reconfigureMenuItems];
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
	NSSize imageSize = self.selectedItem.image.size;
	// Size the image rect to the exact height and width of the selected image
	return NSMakeRect([self edgeInset], roundf(NSMidY(self.bounds) - (imageSize.height / 2.f)), imageSize.width, imageSize.height);
}

- (NSRect)labelFrame {
	NSRect imageFrame = [self imageFrame];
	NSRect arrowFrame = [self arrowFrame];
	CGFloat xOrigin = NSMaxX(imageFrame) + [self interElementSpacing];
	return NSMakeRect(xOrigin, 0.f, NSMinX(arrowFrame) - xOrigin - [self interElementSpacing], NSHeight(self.bounds));
}

- (NSRect)arrowFrame {
	NSSize arrowSize = self.currentArrowImage.size;
	// Size the arrow image to the exact height and width of the image
	return NSMakeRect(NSMaxX(self.bounds) - arrowSize.width - [self edgeInset], roundf(NSMidY(self.bounds) - (arrowSize.height / 2.f)), arrowSize.width, arrowSize.height);
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
		NSPoint origin = [self imageFrame].origin;
		origin.y = 0.f;
		// Offset to line up the menu item image
		// TODO: Figure out a better way to calculate this offset at runtime.
		// There are no geometry methods on NSMenu or NSMenuItem that would
		// allow the retrievel of layout information for menu items
		origin.x -= 22.f; 
		NSPoint location = [self convertPoint:origin toView:nil];
		// Synthesize an event just so we can change the location of the menu
		NSEvent *synthesizedEvent = [NSEvent mouseEventWithType:theEvent.type location:location modifierFlags:theEvent.modifierFlags timestamp:theEvent.timestamp windowNumber:theEvent.windowNumber context:theEvent.context eventNumber:theEvent.eventNumber clickCount:theEvent.clickCount pressure:theEvent.pressure];
		[NSMenu popUpContextMenu:self.menu withEvent:synthesizedEvent forView:self];
	}
}

#pragma mark - Menu Events

- (IBAction)popUpMenuSelectedItem:(id)sender {
	self.selectedItem = sender;
	[self sendActionsForControlEvents:BTRControlEventValueChanged];
	[self handleStateChange];
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