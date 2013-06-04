@class NSString;
@class NSDictionary;
@protocol MLStream;

#define MLTrace \
	do {\
		MLLog(LOG_DEBUG, "%s:%i",__FUNCTION__, __LINE__); \
	} while(NO)

void MLStreamAppendNSString(id< MLStream > stream, NSString *data);
NSDictionary *MLStreamReadJSON(id< MLStream > stream);

