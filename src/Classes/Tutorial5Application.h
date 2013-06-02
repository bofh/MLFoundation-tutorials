#import "KeyValueStorage/KeyValueStorageProtocol.h"

@class MLApplication;
@class KeyValueServer;

@interface Tutorial5Application : MLApplication {
@private
	KeyValueServer *dataProvider_;
}

@end

