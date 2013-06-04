#import <MLFoundation/MLFoundation.h>
#import "KeyValueStorage/KeyValueServer.h"

@interface Tutorial5Application : MLApplication <MLAcceptorDelegate, MLBufferedEventDelegate> {
@private
	KeyValueServer *dataProvider_;
	MLTCPAcceptor *acceptor_;
	MLSessionSet *sessions_;
}

@end

