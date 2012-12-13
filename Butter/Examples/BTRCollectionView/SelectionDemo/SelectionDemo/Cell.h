//
//  Cell.h
//  SelectionDemo
//
//  Created by Jonathan Willing on 12/12/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import <Butter/Butter.h>
#import <Butter/BTRImageView.h>

@interface Cell : BTRCollectionViewCell

@property (nonatomic, strong) NSTextField *label;
@property (nonatomic, strong) BTRImageView *imageView;

@end
