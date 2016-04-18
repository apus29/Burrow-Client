//
//  TransmissionTests.swift
//  Burrow
//
//  Created by Jaden Geller on 4/17/16.
//
//

import XCTest
@testable import Shovel

let data = "The quick brown fox jumped over the lazy dog. The slow green turtle nibbled on the tasty ant. The fluffy gray chinchilla squeaked at the silly hampster. The perky brown puppy sprinted around the grumpy cat.".dataUsingEncoding(NSUTF8StringEncoding)!
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
                "VkdobElIRjFhV05ySUdKeWIzZHVJR1p2ZUNCcWRXMXdaV1FnYjNabGNpQjBhR1V",
                "nYkdGNmVTQmtiMmN1SUZSb1pTQnpiRzkzSUdkeVpXVnVJSFIxY25Sc1pTQnVhV0",
                "ppYkdWa0lHOXVJSFJvWlNCMFlYTjBlU0JoYm5RdUlGUm9aU0JtYkhWbVpua2daM",
                "0poZVNCamFHbHVZMmhwYkd4aElITnhkV1ZoYTJW",
                "0.continue.bacon.tech"
            ],
            [
                "a0lHRjBJSFJvWlNCemFXeHNlU0JvWVcxd2MzUmxjaTRnVkdobElIQmxjbXQ1SUd",
                "KeWIzZHVJSEIxY0hCNUlITndjbWx1ZEdWa0lHRnliM1Z1WkNCMGFHVWdaM0oxYl",
                "hCNUlHTmhkQzQ9",
                "1.continue.bacon.tech"
            ]
            ].map{ $0.joinWithSeparator(".") }
        XCTAssertEqual(expectedResult, domains.map{ String($0) })
    }
    
    func testTransmission() {
        let expectation = expectationWithDescription("Received response")
        var result: Result<NSData>!
        
        let manager = TransmissionManager(domain: "burrow.tech")
        try! manager.transmit(data) { response in
            result = response
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(5) { error in
            if let error = error {
                XCTFail("Failed with error: \(error)")
            }
        }
        XCTAssertEqual(
            ".tac ypmurg eht dnuora detnirps yppup nworb ykrep ehT .retspmah yllis eht ta dekaeuqs allihcnihc yarg yffulf ehT .tna ytsat eht no delbbin eltrut neerg wols ehT .god yzal eht revo depmuj xof nworb kciuq ehT",
            try! String(data: result.value(), encoding: NSUTF8StringEncoding)
        )
    }
}
