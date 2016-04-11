//
//  ShovelTests.swift
//  ShovelTests
//
//  Created by Jaden Geller on 4/10/16.
//
//

import XCTest
@testable import Shovel

class TXTRecordTests: XCTestCase {
    
    func testConstant() {
        let serverMessage = try! ServerMessage.withQuery(
            domain: "constant.test.burrow.tech",
            recordClass: ns_c_in,
            recordType: ns_t_txt,
            bufferSize: 4096
        )
        XCTAssertEqual(1, serverMessage.value.answers.count)
        guard let txtRecord = TXTRecord(serverMessage.value.answers.first!) else {
            fatalError("Unexpected record type.")
        }
        XCTAssertEqual("I am the constant record.", txtRecord.contents)
    }
    
    func testBabies() {
        let serverMessage = try! ServerMessage.withQuery(
            domain: "babies.test.burrow.tech",
            recordClass: ns_c_in,
            recordType: ns_t_txt,
            bufferSize: 4096
        )
        let expectedCount = 9
        XCTAssertEqual(expectedCount, Int(serverMessage.value.answers.count))
        
        var foundMessages: Set<String> = []
        for record in serverMessage.value.answers {
            guard let txtRecord = TXTRecord(record) else {
                fatalError("Unexpected record type.")
            }
            foundMessages.insert(txtRecord.contents)
        }
        
        let expectedMessages = Set((1...expectedCount).map { "Hello world \($0)" })
        XCTAssertEqual(expectedMessages, foundMessages)
    }
    
    func testBacon() {
        let serverMessage = try! ServerMessage.withQuery(
            domain: "bacon.test.burrow.tech",
            recordClass: ns_c_in,
            recordType: ns_t_txt,
            bufferSize: 4096
        )
        XCTAssertEqual(1, serverMessage.value.answers.count)

        guard let txtRecord = TXTRecord(serverMessage.value.answers.first!) else {
            fatalError("Unexpected record type.")
        }
        XCTAssertEqual(
            "Bacon ipsum dolor amet frankfurter filet mignon tenderloin, jowl short loin corned beef jerky beef ribs spare ribs. Kevin bresaola venison jowl filet mignon. Turducken pork belly pig ball tip tail, alcatra brisket leberkas tri-tip fatback jerky pancetta filet mignon tenderloin. Landjaeger cupim drumstick rump shankle doner cow. Meatball prosciutto tri-tip, doner bresaola landjaeger ball tip andouille pork chop cupim ground round ribeye drumstick pastrami. Cow tenderloin picanha prosciutto pancetta, fatback andouille shoulder. Pig drumstick cow, landjaeger short loin chuck beef ribs. Andouille swine leberkas jowl ribeye doner biltong cupim ball tip prosciutto corned beef. T-bone sirloin filet mignon tongue alcatra shank pig short ribs pork belly tenderloin ribeye. Beef picanha pork t-bone bacon tail salami fatback frankfurter ribeye doner turducken. Porchetta doner rump short loin turducken tenderloin sausage pork. Tenderloin t-bone tri-tip shankle. Tri-tip ground round pork belly, landjaeger ham pancetta bresaola meatball ribeye strip steak pig alcatra. Alcatra sausage tri-tip biltong shoulder bresaola. Shankle swine cow, sausage brisket short loin picanha kielbasa turkey strip steak t-bone tongue hamburger. Shank ham hock pork loin, fatback alcatra andouille prosciutto short loin pastrami shankle hamburger. Boudin ham hamburger filet mignon bacon drumstick. Pork chop prosciutto capicola",
            txtRecord.contents)
    }
}
