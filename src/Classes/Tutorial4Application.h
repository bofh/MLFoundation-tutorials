#import <MLFoundation/MLFoundation.h>

@interface Tutorial4Application : MLApplication <MLAcceptorDelegate, MLBufferedEventDelegate> {
	MLTCPAcceptor *acceptor_;
	MLSessionSet *sessions_;
}

- (void)dropStream:(id)stream;

@end
