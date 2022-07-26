import XCTest
import Combine
@testable import OwnIDCoreSDK

/// Tests show that for fixed input there is fixed output
final class SDKTests: XCTestCase {
    
    func testSetUp() {
        //Arrange (given)
        OwnID.CoreSDK.shared.configureForTests()
        
        //Act (when)
        let serverURL = OwnID.CoreSDK.shared.serverURL(for: OwnID.CoreSDK.sdkName)
        
        //Assert (then)
        if !serverURL.absoluteString.contains("gephu5k2dnff2v") {
            XCTFail()
        }
    }
    
    func testSetUpMultipleConfigs() {
        //Arrange (given)
        let additionalName = "additionalName"
        let appID = "gephu5k2dnff2v"
        let redirect = "commmmm.ownid.demo.gigya://ownid/redirect/"
        OwnID.CoreSDK.shared.configureForTests()
        OwnID.CoreSDK.shared.configure(appID: appID, redirectionURL: redirect, userFacingSDK: (additionalName, OwnID.CoreSDK.version), underlyingSDKs: [])
        
        //Act (when)
        let serverURL = OwnID.CoreSDK.shared.serverURL(for: OwnID.CoreSDK.sdkName)
        
        //Assert (then)
        if !serverURL.absoluteString.contains("gephu5k2dnff2v") {
            XCTFail()
        }
    }
}
