//
//  DomainTests.swift
//  Burrow
//
//  Created by Jaden Geller on 4/17/16.
//
//

import XCTest
@testable import Shovel

let parentDomain: Domain = "bacon.tech"

class DomainTests: XCTestCase {
    
    func testDomainPackaging() {
        let continueDomain = parentDomain.prepending("continue")
        
        let text = "The quick brown fox jumped over the lazy dog. The slow green turtle nibbled on the tasty ant. The fluffy green chinchilla squeaked at the silly hampster."
        let data = text.dataUsingEncoding(NSUTF8StringEncoding)!.base64EncodedDataWithOptions([])
        let domains = Domain.package(data, underDomain: { index in
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
                "bFpDQmhkQ0IwYUdVZ2MybHNiSGtnYUdGdGNITjBaWEl1",
                "1.continue.bacon.tech"
            ]
        ].map{ $0.joinWithSeparator(".") }
        XCTAssertEqual(expectedResult, domains.map{ String($0) })
    }
}
