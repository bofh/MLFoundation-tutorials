#import "Tutorial3Application.h"

@implementation Tutorial3Application
// Initialization and deallocation
- (id)init
{
	if (!(self = [super init])) return nil;

	acceptor_ = [[MLTCPAcceptor alloc] init];
	MLReleaseSelfAndReturnNilUnless(acceptor_);

	[acceptor_ setLoop:EVReactor];
	[acceptor_ setPort:80];
	[acceptor_ setDelegate:self];

	return self;
}

- (void)dealloc
{
	[acceptor_ release];
	[super dealloc];
}

// Command line handling
- (void)usage
{
	//              0            10        20        30        40        50        60        70         "
	//     "01234567890123456789012345678901234567890123456789012345678901234567890123456789"
	printf("Usage:\n");
	printf("    %s [options]\n", [[[[NSProcessInfo processInfo] arguments] objectAtIndex:0] UTF8String]);
	printf("\n");
	printf("TCP options:\n");
	printf("  --port <port>               Listen at port <port> (default 80)\n");
	printf("\n");

	[super usage];
}

- (int)port
{
	return [acceptor_ port];
}

- (void)setPort:(int)port
{
	[acceptor_ setPort:port];
}

// MLApplication subclassing
- (BOOL)validateForStart:(NSError **)e
{
	if (![super validateForStart:e]) return NO;
	if (![acceptor_ validateForStart:e]) return NO;
	return YES;
}

- (void)start
{
	if ([self isStarted]) return;
	[super start];
	[acceptor_ start];
}

- (void)stop
{
	if (![self isStarted]) return;
	[super stop];
	[acceptor_ stop];
}

// MLAcceptor delegated methods
- (void)acceptor:(id<MLAcceptor>)acceptor receivedConnection:(id<MLBufferedEvent>)connection
{
	MLLog(LOG_INFO, "Client %@ connected", connection);
}

- (void)acceptor:(id<MLAcceptor>)acceptor error:(NSError *)details
{
	MLLog(LOG_ERROR, "Acceptor fatal error (%@), exiting...", details);
	[self stop];
}

@end
