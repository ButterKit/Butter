//
//  BTRProgressIndicator.h
//  Butter
//
//  Created by Jonathan Willing on 12/25/12.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

typedef NS_ENUM(NSInteger, BTRActivityIndicatorStyle) {
    BTRActivityIndicatorStyleWhite,
    BTRActivityIndicatorStyleGray
};

// An indeterminate activity indicator.
// The API is nearly equivalent to UIActivityIndicator.
#import <Butter/Butter.h>

@interface BTRProgressIndicator : BTRView

// Returns an activity indicator sized to the default indicator size.
- (id)initWithActivityIndicatorStyle:(BTRActivityIndicatorStyle)style;

// Initializes the activity indicator with the default indicator style (BTRActivityIndicatorStyleGray).
- (id)initWithFrame:(NSRect)frameRect;

- (id)initWithFrame:(NSRect)frameRect activityIndicatorStyle:(BTRActivityIndicatorStyle)style;

- (void)startAnimating;
- (void)stopAnimating;

@property (nonatomic, assign) BOOL hidesWhenStopped;
@property (nonatomic, assign) BTRActivityIndicatorStyle activityIndicatorStyle;

@end
