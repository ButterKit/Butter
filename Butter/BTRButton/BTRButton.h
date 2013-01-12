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

@property (nonatomic, strong, readonly) BTRLabel *titleLabel;
@property (nonatomic, strong, readonly) BTRImageView *imageView;

// Sets the content mode on the underlying image view.
@property (nonatomic, assign) BTRViewContentMode contentMode;

// Subclassing hooks
- (CGRect)imageFrame;
- (CGRect)labelFrame;
@end
