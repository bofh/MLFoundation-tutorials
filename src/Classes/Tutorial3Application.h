#import <MLFoundation/MLFoundation.h>

@interface Tutorial3Application : MLApplication <MLAcceptorDelegate> {
	MLTCPAcceptor *acceptor_;
}

@end
