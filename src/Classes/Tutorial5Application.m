#import <MLFoundation/MLFoundation.h>
#import "KeyValueStorage/KeyValueServer.h"
#import "Tutorial5Application.h"

@implementation Tutorial5Application

- (id)init
{
	self = [super init];

	if (self) {
		dataProvider_ = [[KeyValueServer alloc] init];
	}

	return self;
}

- (void)dealloc
{
	[dataProvider_ release];
	[super dealloc];
}

- (BOOL)validateForStart:(NSError **)e
{
	if (![super validateForStart:e]) return NO;
	return YES;
}

- (void)start
{
	if ([self isStarted]) return;
	[super start];
	
	[dataProvider_ setObject:@"Test message" forKey:@"TestKey"];
	NSString *obj = [dataProvider_ objectForKey: @"TestKey"];
	if (obj)
		MLLog(LOG_INFO, [obj UTF8String]);
	
	MLLog(LOG_INFO, "Tutorial5Application#start");
}

- (void)stop
{
	if (![self isStarted]) return;
	[super stop];
	MLLog(LOG_INFO, "Tutorial5Application#stop");
}

@end
