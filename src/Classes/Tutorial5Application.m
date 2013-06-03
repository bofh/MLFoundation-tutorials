#import "Tutorial5Application.h"
#import "KeyValueStorage/StorageCommands.h"
#import "Tools.h"

@interface Tutorial5Application(private)
- (void)dropStream:(id)stream;
- (NSString *)commandResponse:(NSString *)response error:(NSError **)error;
@end

@implementation Tutorial5Application

- (id)init
{
	MLTrace;
	
	self = [super init];

	if (self) {
		sessions_ = [[MLSessionSet alloc] initWithCapacity:1024];
		MLReleaseSelfAndReturnNilUnless(sessions_);

		acceptor_ = [[MLTCPAcceptor alloc] init];
		MLReleaseSelfAndReturnNilUnless(acceptor_);

		[acceptor_ setLoop:EVReactor];
		[acceptor_ setDelegate:self];

		dataProvider_ = [[KeyValueServer alloc] init];
		MLReleaseSelfAndReturnNilUnless(dataProvider_);
	}

	return self;
}

- (void)dealloc
{
	MLTrace;
	MLAssert(acceptor_);
	MLAssert(sessions_);
	
	[dataProvider_ release];
	[acceptor_ release];
	[sessions_ release];
	[super dealloc];
}

- (void)usage
{
	printf("Usage:\n");
	printf("    %s [options]\n", [[[[NSProcessInfo processInfo] arguments] objectAtIndex:0] UTF8String]);
	printf("\n");
	printf("TCP options:\n");
	printf("  --port <port>               Listen at port <port>\n");
	printf("\n");

	[super usage];
}

- (void)setPort:(int)port
{
	MLTrace;
	MLAssert(acceptor_);
	
	[acceptor_ setPort:port];
}

- (BOOL)validateForStart:(NSError **)e
{
	MLTrace;
	MLAssert(acceptor_);
	
	if (![super validateForStart:e]) return NO;
	if (![acceptor_ validateForStart:e]) return NO;
	return YES;
}

- (void)start
{
	MLTrace;
	MLAssert(acceptor_);
	
	if ([self isStarted]) return;
	[super start];
	[acceptor_ start];
}

- (void)stop
{
	MLTrace;
	MLAssert(acceptor_);
	MLAssert(sessions_);
	
	if (![self isStarted]) return;
	[super stop];
	[acceptor_ stop];
	[sessions_ makeObjectsPerformSelector:@selector(stop)];
}

// MLAcceptor
- (void)acceptor:(id<MLAcceptor>)acceptor receivedConnection:(id<MLBufferedEvent>)connection
{
	MLAssert(sessions_);
	MLLog(LOG_DEBUG, "Client from (%@) connected", connection);

	[sessions_ addObject:connection];
	[connection retain];

	[connection setDelegate:self];
	[connection setReadTimeout:5.0];
	[connection start];
}

- (void)acceptor:(id<MLAcceptor>)acceptor error:(NSError *)details
{
	MLLog(LOG_DEBUG, "Acceptor fatal error (%@), existing...", details);
	[self stop];
}

// MLBufferedEvent
- (void)dataAvailableOnEvent:(id<MLBufferedEvent>)stream
{
	MLLog(LOG_DEBUG, "Data available on stream (%@)", stream);
	
	uint64_t len = MLStreamLength(stream);
	if (len < 1)
		return;
	
	MLLog(LOG_DEBUG, "Got (%llu) bytes from stream (%@)", len, stream);
	MLLogHexdump(LOG_DEBUG, MLStreamData(stream), len);
	
	NSDictionary *requestDict = MLStreamReadJSON(stream);
	
	NSString *responseString = nil;
	NSString *keyString = [requestDict objectForKey:kStorageCommandGet];
	if (keyString)
	{
		MLLog(LOG_DEBUG, "Handle get command with key (%@)", keyString);
		responseString = [dataProvider_ objectForKey:keyString];
	}
	else
	{
		NSDictionary *setDict = [requestDict objectForKey:kStorageCommandSet];
		if (setDict)
		{
			NSArray *keysArray = [setDict allKeys];
			keyString = [keysArray objectAtIndex:0];
			NSString *valString = [setDict objectForKey: keyString];
			MLLog(LOG_DEBUG, "Handle set command with key (%@) and value (%@)", keyString, valString);
			
			[dataProvider_ setObject:valString forKey:keyString];
			responseString = valString;
		}
	}
	
	if (responseString == nil)
		responseString = kStorageResponseUnknown;
	
	NSError *error = nil;
	NSString *jsonResponseString = [self commandResponse:responseString error:&error];
	
	MLStreamDrain(stream, len);
	
	if (error)
		MLLog(LOG_DEBUG, "Internal JSON error (%@)", &error);
	
	else
		MLStreamAppendNSString(stream, jsonResponseString);
		
	[self dropStream:stream];
}

- (void)error:(NSError *)details onEvent:(id<MLBufferedEvent>)stream
{
	MLLog(LOG_DEBUG, "Stream (%@) error (%@), closing connection", stream, details);
	[self dropStream:stream];
}

- (void)timeout:(int)what onEvent:(id <MLBufferedEvent>)stream
{
	MLLog(LOG_DEBUG, "Timeout on stream (%@)", stream);
	[self dropStream:stream];
}

- (void)writtenToEvent:(id<MLBufferedEvent>)stream
{
	MLLog(LOG_DEBUG, "Written to stream (%@)", stream);
}

- (void)dropStream:(id)stream
{
	MLTrace;
	MLAssert(sessions_);
	
	[sessions_ removeObject:stream];
	[stream stop];
	[stream flushAndRelease];	
}

- (NSString *)commandResponse:(NSString *)response error:(NSError **)error
{
	NSDictionary *dict = [NSDictionary
		dictionaryWithObjects:[NSArray arrayWithObjects:response, nil]
		forKeys:[NSArray arrayWithObjects:kStorageResponse, nil]];
	
	SBJSON *json = [[SBJSON alloc] init];
	NSString *result = [json stringWithObject:dict error:error];
	
	[json release];
	return result;
}

@end
