#import "Tutorial6Application.h"
#import "Tools.h"

@interface Tutorial6Application(private)
- (NSString *)getCommandRequest:(NSError **)error;
- (NSString *)setCommandRequest:(NSError **)error;
@end

@implementation Tutorial6Application

- (id)init
{
	self = [super init];

	if (self) {
		clientConnection_ = [[MLTCPClientConnection alloc] init];
		MLReleaseSelfAndReturnNilUnless(clientConnection_);
		
		[clientConnection_ setDelegate:self];
		[clientConnection_ setLoop:EVReactor];
		
		commandType_ = kCommandUnknown;
		key_ = nil;
		val_ = nil;
	}

	return self;
}

- (void)dealloc
{
	[clientConnection_ release];
	[super dealloc];
}

// Tutorial6Application
- (void)setHost:(NSString *)host
{
	MLAssert(clientConnection_);
	[clientConnection_ setHost:host];
}

- (void)setPort:(int)port
{
	MLAssert(clientConnection_);
	[clientConnection_ setPort:port];
}

- (void)setSet:(NSString *)key
{
	commandType_ = kCommandSet;
	key_ = key;
}

- (void)setVal:(NSString *)val
{
	val_ = val;
}

- (void)setGet:(NSString *)key
{
	commandType_ = kCommandGet;
	key_ = key;
}

- (NSString *)getCommandRequest:(NSError **)error
{
	NSDictionary *dict = [NSDictionary
		dictionaryWithObjects:[NSArray arrayWithObjects:key_, nil]
		forKeys:[NSArray arrayWithObjects:kStorageCommandGet, nil]];
	
	SBJSON *json = [[SBJSON alloc] init];
	NSString *result = [json stringWithObject:dict error:error];
	
	[json release];
	return result;
}

- (NSString *)setCommandRequest:(NSError **)error
{
	NSDictionary *subDict = [NSDictionary
		dictionaryWithObjects:[NSArray arrayWithObjects:val_, nil]
		forKeys:[NSArray arrayWithObjects:key_, nil]];
	
	NSDictionary *dict = [NSDictionary
		dictionaryWithObjects:[NSArray arrayWithObjects:subDict, nil]
		forKeys:[NSArray arrayWithObjects:kStorageCommandSet, nil]];
	
	SBJSON *json = [[SBJSON alloc] init];
	NSString *result = [json stringWithObject:dict error:error];
	
	[json release];
	return result;
}

// MLActivity
- (BOOL)validateForStart:(NSError **)e
{
	MLAssert(clientConnection_);
	
	if (![super validateForStart:e]) return NO;
	if (![clientConnection_ validateForStart:e]) return NO;
	
	switch (commandType_)
	{
	case kCommandGet:
		break;
	
	case kCommandSet:
		if (val_ == nil)
		{
			*e = [NSError errorWithDomain:MLFoundationErrorDomain
				code:MLApplicationStartError
				localizedDescriptionFormat:@"Did you forget to pass <val>?"];
			return NO;
		}
		break;
	
	case kCommandUnknown:
		*e = [NSError errorWithDomain:MLFoundationErrorDomain
			code:MLApplicationStartError
			localizedDescriptionFormat:@"You should use <get> or <set> command."];
		return NO;
	}
	
	return YES;
}

- (void)start
{
	MLAssert(clientConnection_);
	MLAssert(commandType_ != kCommandUnknown);
	
	if ([self isStarted]) return;
	[super start];
	[clientConnection_ start];
	
	// Build the request.
	NSError *error = nil;
	NSString *request = nil;
	
	switch (commandType_)
	{
	case kCommandGet:
		request = [self getCommandRequest: &error];
		break;
	
	case kCommandSet:
		request = [self setCommandRequest: &error];
		break;
	
	default:
		break;
	}
	
	if (error)
	{
		MLLog(LOG_WARNING, "Internal JSON error.");
		[self stop];
		return;
	}
	
	MLStreamAppendNSString(clientConnection_, request);
	
	MLLog(LOG_INFO, "Tutorial6Application#start");
}

- (void)stop
{
	MLAssert(clientConnection_);
	
	if (![self isStarted]) return;
	[clientConnection_ stop];
	[super stop];
	
	MLLog(LOG_INFO, "Tutorial6Application#stop");
}

- (BOOL)isStarted
{
	return [super isStarted];
}

- (void)usage
{
	printf("Usage:\n");
	printf("    %s [options]\n", [[[[NSProcessInfo processInfo] arguments] objectAtIndex:0] UTF8String]);
	printf("\n");
	printf("TCP options:\n");
	printf("  --host <host>               Connect to host <host>.\n");
	printf("  --port <port>               Connect to port <port>.\n");
	printf("\n");
	printf("Request commands:\n");
	printf("  --set <key> --val <val>     Store <key>-<val> pair in store.\n");
	printf("  --get <key>                 Retrieve value for the specified <key>.\n");
	printf("\n");
	
	[super usage];
}

// MLBufferedEventDelegate
- (void)dataAvailableOnEvent:(id<MLBufferedEvent>)stream
{
	MLLog(LOG_DEBUG, "dataAvailableOnEvent: %@", stream);

	uint64_t len = MLStreamLength(stream);
	if (len < 1)
		return;

	MLLog(LOG_DEBUG, "Got %llu bytes from %@", len, stream);
	MLLogHexdump(LOG_DEBUG, MLStreamData(stream), len);
	
	NSDictionary *responseDict = MLStreamReadJSON(stream);
	NSString *resultString = [responseDict objectForKey:kStorageResponse];
	
	if (resultString)
		printf("%s\n", [resultString UTF8String]);
	else
		printf("Internal error.\n");
	
	[self stop];
}

- (void)error:(NSError *)details onEvent:(id<MLBufferedEvent>)stream
{
	MLLog(LOG_DEBUG, "Stream %@ error (%@), closing connection", stream, details);
	[self stop];
}

- (void)timeout:(int)what onEvent:(id <MLBufferedEvent>)stream
{
	MLLog(LOG_DEBUG, "timeout: %@", stream);
	[self stop];
}

- (void)writtenToEvent:(id<MLBufferedEvent>)stream
{
	MLLog(LOG_DEBUG, "writtenToEvent: %@", stream);
}

@end

