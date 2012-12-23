//
//  BTRButton.h
//  Butter
//
//  Created by Jonathan Willing on 12/21/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import <Butter/BTRControl.h>

@interface BTRButton : BTRControl

- (NSImage *)backgroundImageForControlState:(BTRControlState)state;
- (void)setBackgroundImage:(NSImage *)image forControlState:(BTRControlState)state;

- (NSString *)titleForControlState:(BTRControlState)state;
- (void)setTitle:(NSString *)title forControlState:(BTRControlState)state;

@end
