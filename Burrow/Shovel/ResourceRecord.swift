//
//  ResourceRecord.swift
//  Burrow
//
//  Created by Jaden Geller on 4/10/16.
//
//

extension ResourceRecord {
    var dataBuffer: UnsafeBufferPointer<UInt8> {
        return UnsafeBufferPointer(
            start: ResourceRecordGetData(self),
            count: ResourceRecordGetDataLength(self)
        )
    }
}

extension RecordType {
    static var txt: RecordType {
        return ns_t_txt
    }
}

extension RecordClass {
    static var internet: RecordClass {
        return ns_c_in
    }
}