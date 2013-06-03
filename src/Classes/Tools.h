@class NSString;
@class NSDictionary;
@protocol MLStream;

void MLStreamAppendNSString(id< MLStream > stream, NSString *data);
NSDictionary *MLStreamReadJSON(id< MLStream > stream);

