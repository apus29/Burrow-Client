//
//  Test.m
//  Burrow
//
//  Created by Jaden Geller on 4/10/16.
//
//

#import "ResourceRecord.h"

NSInteger ResourceRecordGetDataLength(ResourceRecord record) {
    return ns_rr_rdlen(record);
}

const u_char *ResourceRecordGetData(ResourceRecord record) {
    return ns_rr_rdata(record);
}

ns_type ResourceRecordGetType(ResourceRecord record) {
    return ns_rr_type(record);
}

