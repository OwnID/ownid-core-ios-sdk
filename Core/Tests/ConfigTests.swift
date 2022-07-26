import XCTest
import Combine
@testable import OwnIDCoreSDK

/// Tests show that for fixed input there is fixed output
final class ConfigTests: XCTestCase {
    
    func testSuccessfulConfigInit() throws {
        //Arrange (given)
        let config = """
            {
              "OwnIDAppID": "gephu5k2dnff2v",
              "OwnIDRedirectionURL": "com.ownid.demo.gigya://ownid/redirect/"
            }
            """
            .data(using: .utf8)!
        let configuration = try! JSONDecoder().decode(OwnID.CoreSDK.Configuration.self, from: config)
        
        //Assert (then)
        XCTAssertEqual(configuration.redirectionURL, "com.ownid.demo.gigya://ownid/redirect/")
    }
    
    func testSuccessfulConfigDirectInit() throws {
        //Arrange (given)
        let appID = "gephu5k2dnff2v"
        let configuration = try! OwnID.CoreSDK.Configuration(appID: appID, redirectionURL: "com.ownid.demo.gigya://ownid/redirect/", environment: .none)
        
        //Assert (then)
        XCTAssertEqual(configuration.redirectionURL, "com.ownid.demo.gigya://ownid/redirect/")
    }
    
    func testErrorConfigInit1() throws {
        //Arrange (given)
        let config = """
            {
              "OwnIDAppID": "gephu5k2dnff2v",
              "OwnIDRedirectionURL": "com.ownid.demo.gigya:"
            }
            """
            .data(using: .utf8)!
        let configuration = try? JSONDecoder().decode(OwnID.CoreSDK.Configuration.self, from: config)
        
        //Assert (then)
        XCTAssertNil(configuration)
    }
    
    func testSuccessfulConfigInit2() throws {
        //Arrange (given)
        let config = """
            {
              "OwnIDAppID": "gephu5k2dnff2v",
              "OwnIDRedirectionURL": "com.ownid.demo.gigya:someaction"
            }
            """
            .data(using: .utf8)!
        let configuration = try! JSONDecoder().decode(OwnID.CoreSDK.Configuration.self, from: config)
        
        //Assert (then)
        XCTAssertEqual(configuration.redirectionURL, "com.ownid.demo.gigya:someaction")
    }
    
    func testSuccessfulConfigInit3() throws {
        //Arrange (given)
        let config = """
            {
              "OwnIDAppID": "gephu5k2dnff2v",
              "OwnIDRedirectionURL": "com.ownid.demo.gigya.screens:/?close=false"
            }
            """
            .data(using: .utf8)!
        let configuration = try! JSONDecoder().decode(OwnID.CoreSDK.Configuration.self, from: config)
        
        //Assert (then)
        XCTAssertEqual(configuration.redirectionURL, "com.ownid.demo.gigya.screens:/?close=false")
    }
    
    func testSucessInit() throws {
        //Arrange (given)
        let config = """
            {
              "OwnIDAppID": "gephu5k2dnff2v",
              "OwnIDRedirectionURL": "com.ownid.demo.gigya://",
            }
            """
            .data(using: .utf8)!
        let configuration = try! JSONDecoder().decode(OwnID.CoreSDK.Configuration.self, from: config)
        
        //Assert (then)
        XCTAssertNotNil(configuration)
    }
    
    func testErrorOnEmptyScheme() throws {
        //Arrange (given)
        let config = """
            {
              "OwnIDAppID": "gephu5k2dnff2v",
              "OwnIDRedirectionURL": "com.ownid.demo.gigya",
            }
            """
            .data(using: .utf8)!
        let configuration = try? JSONDecoder().decode(OwnID.CoreSDK.Configuration.self, from: config)
        
        //Assert (then)
        XCTAssertNil(configuration)
    }
    
    func testErrorOwnIDSuffix() throws {
        //Arrange (given)
        let config = """
            {
              "OwnIDAppID": "gephu5k2dnff2v",
              "OwnIDRedirectionURL": "com.ownid.demo.gigya://ownid/redirect/",
            }
            """
            .data(using: .utf8)!
        let configuration = try? JSONDecoder().decode(OwnID.CoreSDK.Configuration.self, from: config)
        
        //Assert (then)
        XCTAssertNotNil(configuration)
    }
    
    func testErrorNotOwnIDSuffix() throws {
        //Arrange (given)
        let config = """
            {
              "OwnIDAppID": "gephu5k2dnff2v",
              "OwnIDRedirectionURL": "com.ownid.demo.gigya://ownid/redirect/",
            }
            """
            .data(using: .utf8)!
        let configuration = try? JSONDecoder().decode(OwnID.CoreSDK.Configuration.self, from: config)
        
        //Assert (then)
        XCTAssertNotNil(configuration)
    }
    
    func testNotOwnIDSuffixDirectInit() throws {
        //Arrange (given)
        let appID = "gephu5k2dnff2v"
        let configuration = try? OwnID.CoreSDK.Configuration(appID: appID, redirectionURL: "com.ownid.demo.gigya://ownid/redirect/", environment: .none)
        
        //Assert (then)
        XCTAssertNotNil(configuration)
    }
}
