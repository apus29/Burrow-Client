//
//  Test.h
//  Burrow
//
//  Created by Jaden Geller on 4/10/16.
//
//

@import Foundation;
@import CResolver;

typedef ns_rr ResourceRecord;
typedef ns_type RecordType;
typedef ns_class RecordClass;

NSInteger ResourceRecordGetDataLength(ResourceRecord record);
const u_char *ResourceRecordGetData(ResourceRecord record);
RecordType ResourceRecordGetType(ResourceRecord record);
int ResourceRecordFromQuery(const char *domain, RecordClass class, RecordType type, u_char *answerBuffer, int bufferSize, ResourceRecord *result);

