#import "Tutorial5Application.h"

@implementation Tutorial5Application

- (BOOL)validateForStart:(NSError **)e
{
	if (![super validateForStart:e]) return NO;
	return YES;
}

- (void)start
{
	if ([self isStarted]) return;
	[super start];
	MLLog(LOG_INFO, "Tutorial5Application#start");
}

- (void)stop
{
	if (![self isStarted]) return;
	[super stop];
	MLLog(LOG_INFO, "Tutorial5Application#stop");
}

@end
