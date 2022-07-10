import XCTest
import Combine
@testable import OwnIDCoreSDK

final class TestExtensionLogger: ExtensionLoggerProtocol {
    var identifier = UUID()
    var events = [OwnID.CoreSDK.StandardMetricLogEntry]()
    
    func log(_ entry: OwnID.CoreSDK.StandardMetricLogEntry) {
        events.append(entry)
    }
}

/// Tests show that for fixed input there is fixed output
final class LoggerTests: XCTestCase {
    
    override class func setUp() {
        OwnID.CoreSDK.shared.configureForTests()
    }
    
    func testSetUpIntegrationOnSDKStart() throws {
        //Arrange (given)
        let expected: OwnID.CoreSDK.StandardMetricLogEntry = OwnID.CoreSDK.CoreMetricLogEntry.entry(OwnID.CoreSDK.self)
        var actual: OwnID.CoreSDK.StandardMetricLogEntry = OwnID.CoreSDK.CoreMetricLogEntry.entry(OwnID.CoreSDK.self)
        
         let myLogger = TestExtensionLogger()
        OwnID.CoreSDK.logger.add(myLogger)
        
        //Act (when)
        OwnID.CoreSDK.shared.configureForTests()
        
        //Assert (then)
        actual = try XCTUnwrap(myLogger.events.first)
        XCTAssertEqual(actual.codeInitiator, expected.codeInitiator)
    }
}
