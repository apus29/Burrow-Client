//
//  TransmissionTests.swift
//  Burrow
//
//  Created by Jaden Geller on 4/17/16.
//
//

import XCTest
@testable import Shovel

let data = "The quick brown fox jumped over the lazy dog. The slow green turtle nibbled on the tasty ant. The fluffy green chinchilla squeaked at the silly hampster. The perky brown puppy sprinted around the grumpy cat.".dataUsingEncoding(NSUTF8StringEncoding)!
let parentDomain: Domain = "bacon.tech"

class TransmissionTests: XCTestCase {
    
    func testDomainPackaging() {
        let continueDomain = parentDomain.prepending("continue")
        
        let encodedData = data.base64EncodedDataWithOptions([])
        let domains = TransmissionManager.package(encodedData, underDomain: { index in
            return continueDomain.prepending(String(index))
        })

        let expectedResult = [
            [
                "0psWlc0Z1kyaHBibU5vYVd4c1lTQnpjWFZsWVd0",
                "ppYkdWa0lHOXVJSFJvWlNCMFlYTjBlU0JoYm5RdUlGUm9aU0JtYkhWbVpua2daM",
                "nYkdGNmVTQmtiMmN1SUZSb1pTQnpiRzkzSUdkeVpXVnVJSFIxY25Sc1pTQnVhV0",
                "VkdobElIRjFhV05ySUdKeWIzZHVJR1p2ZUNCcWRXMXdaV1FnYjNabGNpQjBhR1V",
                "0.continue.bacon.tech"
            ],
            [
                "cxd2VTQmpZWFF1",
                "CaWNtOTNiaUJ3ZFhCd2VTQnpjSEpwYm5SbFpDQmhjbTkxYm1RZ2RHaGxJR2R5ZF",
                "bFpDQmhkQ0IwYUdVZ2MybHNiSGtnYUdGdGNITjBaWEl1SUZSb1pTQndaWEpyZVN",
                "1.continue.bacon.tech"
            ]
            ].map{ $0.joinWithSeparator(".") }
        XCTAssertEqual(expectedResult, domains.map{ String($0) })
    }
    
    func testTransmission() {
        let manager = TransmissionManager(domain: "burrow.tech")
        try! manager.transmit(data) { response in
            print("response", response)
            exit(0)
        }
        dispatch_main()
    }
}
