import XCTest
import Combine
@testable import OwnIDCoreSDK

/// Tests show that for fixed input there is fixed output
final class TypesTests: XCTestCase {
    
    func testEmailIsInvalid() throws {
        //Arrange (given)
        let email0 = OwnID.CoreSDK.Email(rawValue: "")
        let email1 = OwnID.CoreSDK.Email(rawValue: "example@@gmail.com")
        let email2 = OwnID.CoreSDK.Email(rawValue: "example@gmail..com")
        let email3 = OwnID.CoreSDK.Email(rawValue: "examplegmail.com")
        let email4 = OwnID.CoreSDK.Email(rawValue: "Тест@gmail.com")
        let email5 = OwnID.CoreSDK.Email(rawValue: ".example@gmail.com")
        let email6 = OwnID.CoreSDK.Email(rawValue: "example @gmail.com")
        let email7 = OwnID.CoreSDK.Email(rawValue: " Exanple@gmail.com ")
        let email8 = OwnID.CoreSDK.Email(rawValue: "example@gmail")
        
        //Assert (then)
        XCTAssertFalse(email0.isValid)
        XCTAssertFalse(email1.isValid)
        XCTAssertFalse(email2.isValid)
        XCTAssertFalse(email3.isValid)
        XCTAssertFalse(email4.isValid)
        XCTAssertFalse(email5.isValid)
        XCTAssertFalse(email6.isValid)
        XCTAssertFalse(email7.isValid)
        XCTAssertFalse(email8.isValid)
    }
    
    func testEmailIsValid() throws {
        //Arrange (given)
        let email1 = OwnID.CoreSDK.Email(rawValue: "EXAMPLE@GMAIL.COM")
        let email2 = OwnID.CoreSDK.Email(rawValue: "example+tag@gmail.com")
        let email3 = OwnID.CoreSDK.Email(rawValue: "Example!@gmal.com")
        let email4 = OwnID.CoreSDK.Email(rawValue: "Example_test@gmail.com")
        let email5 = OwnID.CoreSDK.Email(rawValue: "example*test@gmail.xom")
        let email6 = OwnID.CoreSDK.Email(rawValue: "example#1234567890@gmail.com")
        let email7 = OwnID.CoreSDK.Email(rawValue: "Example.test@gmail.com")
        
        //Assert (then)
        XCTAssertTrue(email1.isValid)
        XCTAssertTrue(email2.isValid)
        XCTAssertTrue(email3.isValid)
        XCTAssertTrue(email4.isValid)
        XCTAssertTrue(email5.isValid)
        XCTAssertTrue(email6.isValid)
        XCTAssertTrue(email7.isValid)
    }
}
