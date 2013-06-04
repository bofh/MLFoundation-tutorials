#import <Foundation/Foundation.h>
#import <MLFoundation/MLFoundation.h>
#import "KeyValueStorage/StorageCommands.h"

@interface Tutorial6Application : MLApplication <MLBufferedEventDelegate> {
@private
	MLTCPClientConnection *clientConnection_;
	
	enum CommandType {
		kCommandGet = 0,
		kCommandSet,
		kCommandUnknown,
	} commandType_;
	NSString *key_;
	NSString *val_;
}

@end

