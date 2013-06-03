#import <Foundation/Foundation.h>
#import <MLFoundation/MLFoundation.h>

// It is too pedantic to deal with C functions here,
// but we should pass char *, not const char * to MLStreamAppendString.
void MLStreamAppendNSString(id< MLStream > stream, NSString *data)
{
	const char *constData = [data UTF8String];
	uint32_t dataLength = strlen(constData);
	char *mutableData = (char *)malloc(dataLength + 1);
	mutableData = strcpy(mutableData, constData);
	
	(void) MLStreamAppendString(stream, mutableData);
	
	free(mutableData);
}