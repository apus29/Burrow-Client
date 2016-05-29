//
//  ShovelTests.swift
//  ShovelTests
//
//  Created by Jaden Geller on 4/10/16.
//
//

import XCTest
@testable import Shovel
import Logger

class TXTRecordTests: XCTestCase {
    override func setUp() {
        Logger.enable(minimumSeverity: .verbose)
    }
    
    func testConstant() {
        let expectation = expectationWithDescription("received")
        
        try! DNSResolver.resolveTXT("constant.test.burrow.tech") { response in
            let txtRecords = try! response.unwrap()
            
            XCTAssertEqual(["I am the constant record."], txtRecords.map { $0.contents })
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(10) { error in
            if let error = error {
                XCTFail("Failed with error: \(error)")
            }
        }
    }
    
    func testBabies() {
        let expectedCount = 9
        let expectedMessages = Set((1...expectedCount).map { "Hello world \($0)" })

        let expectation = expectationWithDescription("received")

        try! DNSResolver.resolveTXT("babies.test.burrow.tech") { response in
            let txtRecords = try! response.unwrap()
            
            XCTAssertEqual(expectedCount, txtRecords.count)
            XCTAssertEqual(expectedMessages, Set(txtRecords.map{ $0.contents }))
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(10) { error in
            if let error = error {
                XCTFail("Failed with error: \(error)")
            }
        }
    }

    func testBacon() {
        let expectedMessage = "Bacon ipsum dolor amet frankfurter filet mignon tenderloin, jowl short loin corned beef jerky beef ribs spare ribs. Kevin bresaola venison jowl filet mignon. Turducken pork belly pig ball tip tail, alcatra brisket leberkas tri-tip fatback jerky pancetta filet mignon tenderloin. Landjaeger cupim drumstick rump shankle doner cow. Meatball prosciutto tri-tip, doner bresaola landjaeger ball tip andouille pork chop cupim ground round ribeye drumstick pastrami. Cow tenderloin picanha prosciutto pancetta, fatback andouille shoulder. Pig drumstick cow, landjaeger short loin chuck beef ribs. Andouille swine leberkas jowl ribeye doner biltong cupim ball tip prosciutto corned beef. T-bone sirloin filet mignon tongue alcatra shank pig short ribs pork belly tenderloin ribeye. Beef picanha pork t-bone bacon tail salami fatback frankfurter ribeye doner turducken. Porchetta doner rump short loin turducken tenderloin sausage pork. Tenderloin t-bone tri-tip shankle. Tri-tip ground round pork belly, landjaeger ham pancetta bresaola meatball ribeye strip steak pig alcatra. Alcatra sausage tri-tip biltong shoulder bresaola. Shankle swine cow, sausage brisket short loin picanha kielbasa turkey strip steak t-bone tongue hamburger. Shank ham hock pork loin, fatback alcatra andouille prosciutto short loin pastrami shankle hamburger. Boudin ham hamburger filet mignon bacon drumstick. Pork chop prosciutto capicola"
        let expectation = expectationWithDescription("received")

        try! DNSResolver.resolveTXT("bacon.test.burrow.tech") { response in
            let txtRecords = try! response.unwrap()
            
            XCTAssertEqual([expectedMessage], txtRecords.map{ $0.contents })
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(10) { error in
            if let error = error {
                XCTFail("Failed with error: \(error)")
            }
        }
    }
}
