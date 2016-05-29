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
let testPrefix = "test-"

// This message must be domain safe.
// Note that message MUST start with "test-" to indicate that we're
let message = testPrefix + "The-quick-brown-fox-jumped-over-the-lazy-dog-The-slow-green-turtle-nibbled-on-the-tasty-ant-The-fluffy-gray-chinchilla-squeaked-at-the-silly-hampster-The-perky-brown-puppy-sprinted-around-the-grumpy-cat-The-quick-brown-fox-jumped-over-the-lazy-dog-The-slow-green-turtle-nibbled-on-the-tasty-ant-The-fluffy-gray-chinchilla-squeaked-at-the-silly-hampster-The-perky-brown-puppy-sprinted-around-the-grumpy-cat-The-quick-brown-fox-jumped-over-the-lazy-dog-The-slow-green-turtle-nibbled-on-the-tasty-ant-The-fluffy-gray-chinchilla-squeaked-at-the-silly-hampster-The-perky-brown-puppy-sprinted-around-the-grumpy-cat"

struct RandomSequence<C: CollectionType where C.Index.Distance == Int>: SequenceType {
    let source: C
    
    func generate() -> AnyGenerator<C.Generator.Element> {
        return AnyGenerator {
            self.source[self.source.startIndex.advancedBy(Int(arc4random_uniform(UInt32(self.source.count))))]
        }
    }
}

class TransmissionTests: XCTestCase {
    
    override func setUp() {
        Logger.enable(minimumSeverity: .verbose)
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
        
        try! manager.transmit(domainSafeMessage: message) { response in
            result = try! response.unwrap()
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(35) { error in
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
    
    func testThroughputSingleTiny() {
        measureMetrics([XCTPerformanceMetric_WallClockTime], automaticallyStartMeasuring: false) {
            self.buildTestThroughput(bytesPerPacket: 140, numberOfPackets: 1, timeout: 20)
        }
    }
    
    func testThroughputFewTiny() {
        measureMetrics([XCTPerformanceMetric_WallClockTime], automaticallyStartMeasuring: false) {
            self.buildTestThroughput(bytesPerPacket: 140, numberOfPackets: 10, timeout: 90)
        }
    }
    
    func testThroughputManyTiny() {
        measureMetrics([XCTPerformanceMetric_WallClockTime], automaticallyStartMeasuring: false) {
            self.buildTestThroughput(bytesPerPacket: 140, numberOfPackets: 100, timeout: 60 * 5)
        }
    }
    
    func testThroughputSingleLarge() {
        measureMetrics([XCTPerformanceMetric_WallClockTime], automaticallyStartMeasuring: false) {
            self.buildTestThroughput(bytesPerPacket: 1400, numberOfPackets: 1, timeout: 60)
        }
    }
    
    func testThroughputFewLarge() {
        measureMetrics([XCTPerformanceMetric_WallClockTime], automaticallyStartMeasuring: false) {
            self.buildTestThroughput(bytesPerPacket: 1400, numberOfPackets: 10, timeout: 60 * 5)
        }
    }
    
    func testThroughputManyLarge() {
        measureMetrics([XCTPerformanceMetric_WallClockTime], automaticallyStartMeasuring: false) {
            self.buildTestThroughput(bytesPerPacket: 1400, numberOfPackets: 100, timeout: 60 * 20)
        }
    }
    
    func buildTestThroughput(bytesPerPacket bytesPerPacket: Int, numberOfPackets: Int, timeout: Double) {
        log.debug("Beginning throughput test iteration")
        
        let allowedCharacters = "abcdefghijklmnopqrstuvwxyz".characters
        
        let manager = TransmissionManager(domain: parentDomain)
        let packets = Repeat(
            count: numberOfPackets,
            repeatedValue: RandomSequence(source: allowedCharacters)
        ).lazy.map { testPrefix + String($0.prefix(bytesPerPacket - testPrefix.characters.count)) }
        
        startMeasuring()
        var errors: [ErrorType] = []
        for (index, packet) in packets.enumerate() {
            let expectation = expectationWithDescription("Packet \(index)")
            
            try! manager.transmit(domainSafeMessage: packet) { response in
                do {
                    let result = try response.unwrap()
                    let expected = String(packet.characters.reverse())
                    guard result == expected else {
                        throw NSError(domain: "test.burrow.tech", code: 0, userInfo: [
                            "index" : index,
                            "expected" : expected,
                            "received" : result
                            ])
                    }
                } catch let error {
                    errors.append(error)
                }
                expectation.fulfill()
            }
        }
        waitForExpectationsWithTimeout(timeout) { error in
            if let error = error {
                XCTFail("Failed with error: \(error)")
            } else if !errors.isEmpty {
                XCTFail("Packet response errors: \(errors)")
            }
        }
        stopMeasuring()
        log.debug("Completed throughput test iteration")
    }
}
