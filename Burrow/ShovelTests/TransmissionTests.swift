//
//  TransmissionTests.swift
//  Burrow
//
//  Created by Jaden Geller on 4/17/16.
//
//

import XCTest
@testable import Shovel
import Logger

let parentDomain: Domain = "burrow.tech"

// This message must be domain safe.
// Note that message MUST start with "test-" to indicate that we're
let message = "test-" + "The-quick-brown-fox-jumped-over-the-lazy-dog-The-slow-green-turtle-nibbled-on-the-tasty-ant-The-fluffy-gray-chinchilla-squeaked-at-the-silly-hampster-The-perky-brown-puppy-sprinted-around-the-grumpy-cat-The-quick-brown-fox-jumped-over-the-lazy-dog-The-slow-green-turtle-nibbled-on-the-tasty-ant-The-fluffy-gray-chinchilla-squeaked-at-the-silly-hampster-The-perky-brown-puppy-sprinted-around-the-grumpy-cat-The-quick-brown-fox-jumped-over-the-lazy-dog-The-slow-green-turtle-nibbled-on-the-tasty-ant-The-fluffy-gray-chinchilla-squeaked-at-the-silly-hampster-The-perky-brown-puppy-sprinted-around-the-grumpy-cat"

class TransmissionTests: XCTestCase {
    
    override func setUp() {
        Logger.enable(minimumSeverity: .debug)
    }
    
    func testDomainPackaging() {
        let continueDomain = parentDomain.prepending("continue")
        
        let domains = DomainPackagingMessage(domainSafeMessage: message, underDomain: { index in
            return continueDomain.prepending(String(index))
        })

        let expectedResult = [
            [
                "test-The-quick-brown-fox-jumped-over-the-lazy-dog-The-slow-gree",
                "n-turtle-nibbled-on-the-tasty-ant-The-fluffy-gray-chinchilla-sq",
                "ueaked-at-the-silly-hampster-The-perky-brown-puppy-sprinted-aro",
                "und-the-grumpy-cat-The-quick-brown-fox",
                "0.continue.burrow.tech"
            ],
            [
                "-jumped-over-the-lazy-dog-The-slow-green-turtle-nibbled-on-the-",
                "tasty-ant-The-fluffy-gray-chinchilla-squeaked-at-the-silly-hamp",
                "ster-The-perky-brown-puppy-sprinted-around-the-grumpy-cat-The-q",
                "uick-brown-fox-jumped-over-the-lazy-do",
                "1.continue.burrow.tech"
            ],
            [
                "g-The-slow-green-turtle-nibbled-on-the-tasty-ant-The-fluffy-gra",
                "y-chinchilla-squeaked-at-the-silly-hampster-The-perky-brown-pup",
                "py-sprinted-around-the-grumpy-cat",
                "2.continue.burrow.tech"
            ]
        ].map{ $0.joinWithSeparator(".") }
        XCTAssertEqual(expectedResult, domains.map{ String($0) })
    }
    
    func testTransmission() {
        let expectation = expectationWithDescription("Received response")
        var result: String!
        
        let manager = TransmissionManager(domain: parentDomain)
        
        manager.transmit(domainSafeMessage: message) { response in
            result = try! response.unwrap()
            expectation.fulfill()
            expectation
        }
        
        waitForExpectationsWithTimeout(15) { error in
            if let error = error {
                XCTFail("Failed with error: \(error)")
            } else {
                XCTAssertEqual(
                    String(message.characters.reverse()),
                    result
                )
            }
        }
    }
}
