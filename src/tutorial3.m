#import <MLFoundation/MLFoundation.h>
#import "Classes/Tutorial3Application.h"

int main(int argc, char *argv[])
{
	[MLLogger setLogLevel:LOG_VDEBUG];

	Tutorial3Application *app = [[Tutorial3Application alloc] init];
	[app processCommandLine];

	NSError *startError;
	if (![app validateForStart:&startError]) {
		MLLog(LOG_FATAL, "FATAL: Unable to start application:\n%@", startError);
		[app usage];
	}

	MLLog(LOG_INFO, "Starting Tutorial3Application, press ^C to quit");
	[app run];

	[app release];

	MLLog(LOG_INFO, "Bye!");
	return 0;
}

