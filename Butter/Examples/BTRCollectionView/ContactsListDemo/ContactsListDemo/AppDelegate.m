//
//  AppDelegate.m
//  ContactsListDemo
//
//  Created by Indragie Karunaratne on 2012-12-25.
//  Copyright (c) 2012 ButterKit. All rights reserved.
//

#import "AppDelegate.h"
#import "Row.h"
#import "SectionHeader.h"
#import <AddressBook/AddressBook.h>

@implementation AppDelegate {
	NSArray *_sections;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	ABAddressBook *addressBook = [ABAddressBook sharedAddressBook];
	NSArray *people = [addressBook people];
	NSMutableDictionary *sectionsDictionary = [NSMutableDictionary dictionary];
	[people enumerateObjectsUsingBlock:^(ABPerson *person, NSUInteger idx, BOOL *stop) {
		NSString *firstName = [person valueForProperty:kABFirstNameProperty];
		NSString *lastName = [person valueForProperty:kABLastNameProperty];
		if (firstName.length) {
			NSString *firstLetter = [[firstName substringToIndex:1] uppercaseString];
			NSMutableArray *thePeople = sectionsDictionary[firstLetter];
			if (!thePeople) thePeople = [NSMutableArray array];
			[thePeople addObject:[NSString stringWithFormat:@"%@ %@", firstName, lastName]];
			sectionsDictionary[firstLetter] = thePeople;
		}
	}];
	NSArray *sortedKeys = [[sectionsDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
	NSMutableArray *sections = [NSMutableArray arrayWithCapacity:sectionsDictionary.count];
	[sortedKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[sections addObject:sectionsDictionary[obj]];
	}];
	_sections = sections;
	BTRCollectionViewListLayout *layout = [BTRCollectionViewListLayout new];
	layout.headerReferenceHeight = 20.f;
	layout.rowHeight = 30.f;
	[self.collectionView setCollectionViewLayout:layout animated:NO];
	[self.collectionView registerNib:[[NSNib alloc] initWithNibNamed:@"Row" bundle:nil] forCellWithReuseIdentifier:@"Row"];
	[self.collectionView registerNib:[[NSNib alloc] initWithNibNamed:@"SectionHeader" bundle:nil] forSupplementaryViewOfKind:BTRCollectionElementKindSectionHeader withReuseIdentifier:@"SectionHeader"];
}

#pragma mark - BTRCollectionViewDataSource

- (NSUInteger)collectionView:(BTRCollectionView *)collectionView numberOfItemsInSection:(NSUInteger)section
{
	return [_sections[section] count];
}

- (BTRCollectionViewCell *)collectionView:(BTRCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	Row *row = [collectionView dequeueReusableCellWithReuseIdentifier:@"Row" forIndexPath:indexPath];
	row.textField.stringValue = _sections[indexPath.section][indexPath.row];
	return row;
}

- (NSUInteger)numberOfSectionsInCollectionView:(BTRCollectionView *)collectionView
{
	return [_sections count];
}

- (BTRCollectionReusableView *)collectionView:(BTRCollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
	if ([kind isEqualToString:BTRCollectionElementKindSectionHeader]) {
		SectionHeader *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"SectionHeader" forIndexPath:indexPath];
		header.textField.stringValue = [_sections[indexPath.section][0] substringToIndex:1];
		return header;
	}
	return nil;
}
@end
