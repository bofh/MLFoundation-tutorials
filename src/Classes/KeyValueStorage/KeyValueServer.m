#import <Foundation/Foundation.h>
#import <MLFoundation/MLCore/MLAssert.h>
#import <MLFoundation/MLCore/MLLogger.h>
#import <MLFoundation/MLCore/MLIdioms.h>
#import "KeyValueServer.h"

static NSString * const kStorageLocation = @"/tmp/KeyValueStorage.db";

@interface KeyValueServer (private)
- (void)save;
@end

@implementation KeyValueServer

- (id)init
{
	self = [super init];

	if (self) {
		storage_ = [[NSMutableDictionary alloc] initWithContentsOfFile: kStorageLocation];
		if (!storage_)
			storage_ = [[NSMutableDictionary alloc] init];
		MLReleaseSelfAndReturnNilUnless(storage_);
	}

	return self;
}

- (void)dealloc
{
	[storage_ release];
	[super dealloc];
}

- (id)objectForKey:(id)aKey
{
	MLAssert(storage_);
	return [storage_ objectForKey: aKey];
}

- (void)setObject:(id)anObject forKey:(id < NSCopying >)aKey
{
	MLAssert(storage_);
	[storage_ setObject:anObject forKey:aKey];
	[self save];
}

- (void)save
{
	MLAssert(storage_);
	[storage_ writeToFile:kStorageLocation atomically: YES];
}

@end

