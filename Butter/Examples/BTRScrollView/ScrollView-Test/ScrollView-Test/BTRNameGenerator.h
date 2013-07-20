//
//  BTRNameGenerator.h
//  ScrollView-Test
//
//  Created by Zach Waldowski on 7/20/13.
//  Copyright (c) 2013 ButterKit. All rights reserved.
//
//  Derived from "NameGenerator"
//  https://github.com/rakkarage/objective-c-name-generator
//  Copyright (c) 2011. Licensed under MIT.
//

@interface BTRNameGenerator : NSObject

+ (BTRNameGenerator *)sharedGenerator;

- (NSString *)getName;

- (NSString *)getName:(BOOL)generated male:(BOOL)sex prefix:(BOOL)prefix postfix:(BOOL)postfix;

@end
