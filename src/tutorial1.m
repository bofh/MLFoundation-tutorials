#import <MLFoundation/MLFoundation.h>

int main(int argc, char *argv[])
{
	[MLLogger setLogLevel:LOG_VDEBUG];
	MLLog(LOG_INFO, "MLFoundation tutorial #1");
	return 0;
}

