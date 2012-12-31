//
//  BTRPopUpButton.h
//  Butter
//
//  Created by Indragie Karunaratne on 2012-12-30.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import <Butter/Butter.h>

@interface BTRPopUpButton : BTRControl
@property (nonatomic, strong, readonly) BTRImageView *imageView;
@property (nonatomic, strong, readonly) BTRLabel *label;

@property (nonatomic, strong, readonly) BTRImageView *backgroundImageView;
@property (nonatomic, strong, readonly) BTRImageView *arrowImageView;

@property (nonatomic, copy) IBOutlet NSMenu *menu;
@property (nonatomic, strong) NSMenuItem *selectedItem;

- (void)selectItemAtIndex:(NSUInteger)index;

- (NSImage *)arrowImageForControlState:(BTRControlState)state;
- (void)setArrowImage:(NSImage *)image forControlState:(BTRControlState)state;

// Can be overriden by subclasses to customize layout
// The frame of the image view 
- (NSRect)imageFrame;
// The frame of the text label
- (NSRect)labelFrame;
// The frame of the arrow image view
- (NSRect)arrowFrame;
// The padding between each element (between image and label, and label and arrow)
- (CGFloat)interElementSpacing;
@property (nonatomic, strong, readonly) NSImage *currentArrowImage;
@end
