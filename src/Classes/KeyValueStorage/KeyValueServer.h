#import "KeyValueStorageProtocol.h"

@class NSObject;
@class NSMutableDictionary;

@interface KeyValueServer : NSObject <KeyValueStorageProtocol> {
@protected
	NSMutableDictionary *storage_;
}

@end

