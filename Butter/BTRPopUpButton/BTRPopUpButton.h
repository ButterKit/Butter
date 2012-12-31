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
@property (nonatomic, strong, readonly) BTRImageView *arrowImageView;

- (NSImage *)arrowImageForControlState:(BTRControlState)state;
- (void)setArrowImage:(NSImage *)image forControlState:(BTRControlState)state;
@end
