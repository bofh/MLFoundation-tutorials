#import "Tutorial4Application.h"

@implementation Tutorial4Application
// Initialization and deallocation
- (id)init
{
	if (!(self = [super init])) return nil;

	sessions_ = [[MLSessionSet alloc] initWithCapacity:1024];
	MLReleaseSelfAndReturnNilUnless(sessions_);

	acceptor_ = [[MLTCPAcceptor alloc] init];
	MLReleaseSelfAndReturnNilUnless(acceptor_);

	[acceptor_ setLoop:EVReactor];
	[acceptor_ setPort:7];
	[acceptor_ setDelegate:self];

	return self;
}

- (void)dealloc
{
	[acceptor_ release];
	[sessions_ release];
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
	printf("  --port <port>               Listen at port <port> (default 7)\n");
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
	[sessions_ makeObjectsPerformSelector:@selector(stop)];
}

// MLAcceptor delegated methods
- (void)acceptor:(id<MLAcceptor>)acceptor receivedConnection:(id<MLBufferedEvent>)connection
{
	MLLog(LOG_INFO, "Client from %@ connected", connection);

	[sessions_ addObject:connection]; // does not retain
	[connection retain]; // connections are autoreleased here, need to save them

	[connection setDelegate:self];

	[connection setReadTimeout:5.0];
	[connection start];
}

- (void)acceptor:(id<MLAcceptor>)acceptor error:(NSError *)details
{
	MLLog(LOG_ERROR, "Acceptor fatal error (%@), exiting...", details);
	[self stop];
}

// MLBufferedEvent delegated methods
- (void)dataAvailableOnEvent:(id<MLBufferedEvent>)stream
{
	MLLog(LOG_DEBUG, "dataAvailableOnEvent: %@", stream);

	uint64_t len = MLStreamLength(stream);
	if (len < 1)
		return;

	MLLog(LOG_DEBUG, "Got %llu bytes from %@", len, stream);
	MLLogHexdump(LOG_DEBUG, MLStreamData(stream), len);

	MLStreamAppendBytes(stream, MLStreamData(stream), len);

	if (len > 0)
		MLStreamDrain(stream, len);

	[self dropStream:stream];
}

- (void)error:(NSError *)details
	  onEvent:(id<MLBufferedEvent>)stream
{
	MLLog(LOG_DEBUG, "Stream %@ error (%@), closing connection", stream, details);
	[self dropStream:stream];
}

- (void)timeout:(int)what
		onEvent:(id <MLBufferedEvent>)stream
{
	MLLog(LOG_DEBUG, "timeout: %@", stream);
	[self dropStream:stream];
}

- (void)writtenToEvent:(id<MLBufferedEvent>)stream
{
	MLLog(LOG_DEBUG, "writtenToEvent: %@", stream);
}

// Misc. stuff
- (void)dropStream:(id)stream
{
	[sessions_ removeObject:stream];
	[stream stop];
	[stream flushAndRelease];	
}

@end
