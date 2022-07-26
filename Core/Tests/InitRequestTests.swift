import XCTest
import Combine
import TestsMocks
@testable import OwnIDCoreSDK

/// Tests show that for fixed input there is fixed output
final class InitRequestTests: XCTestCase {
    //for each test case we have running new instance of XCTestCase, so we do not need to reset bag
    var bag = Set<AnyCancellable>()
    
    var url: OwnID.CoreSDK.ServerURL {
        OwnID.CoreSDK.shared.statusURL(for: OwnID.CoreSDK.sdkName)
    }

    override class func setUp() {
        OwnID.CoreSDK.shared.configureForTests()
    }

    func testInitReqestCorrectBody() throws {
        let expectation = self.expectation(description: #function)
        var response: OwnID.CoreSDK.Init.Response?
        let string =
            """
                {
                  "url": "https://sign.dev.ownid.com/sign?q=https%3a%2f%2fgigya.single.demo.dev.ownid.com%2fownid%2fkhPIZQPHvEiG4vKPk5stCg%2fstart&ll=3&l=en",
                  "context": "khPIZQPHvEiG4vKPk5stCg",
                  "nonce": "93ab0b0b-aed8-4353-a4ae-8d55ff9005aa"
                }
            """

        //Arrange (given)
        OwnID.CoreSDK.Init.Request(type: .register,
                           url: url,
                           sessionChallenge: "xcyHWNv1bsMEkVISvUr5H6s4cuylLI0gj-wykLaHQKI",
                           token: .none,
                           webLanguages: OwnID.CoreSDK.Languages.init(rawValue: []),
                           provider: MockAPI.correctBody(for: string))
            //Act (when)
            .perform()
            .sink { completion in
                if case .failure(let error) = completion {
                    XCTFail("\(error)")
                }
            } receiveValue: { value in
                response = value
                expectation.fulfill()
            }
            .store(in: &bag)

        waitForExpectations(timeout: 2)
        
        //Assert (then)
        XCTAssertNotNil(response)
    }

    func testInitReqestError() throws {
        let expectation = self.expectation(description: #function)
        var resultedError: OwnID.CoreSDK.Error?

        //Arrange (given)
        OwnID.CoreSDK.Init.Request(type: .register,
                           url: url,
                           sessionChallenge: "xcyHWNv1bsMEkVISvUr5H6s4cuylLI0gj-wykLaHQKI",
                           token: .none,
                           webLanguages: OwnID.CoreSDK.Languages.init(rawValue: []),
                           provider: MockAPI.errorProvider)
            //Act (when)
            .perform()
            .sink { completion in
                if case .failure(let error) = completion {
                    resultedError = error
                    expectation.fulfill()
                }
            } receiveValue: { value in
                XCTFail("\(value)")
            }
            .store(in: &bag)

        waitForExpectations(timeout: 2)
        
        //Assert (then)
        XCTAssertNotNil(resultedError)
    }

    func testInitReqestBodyError() throws {
        let expectation = self.expectation(description: #function)
        var resultedError: OwnID.CoreSDK.Error?

        //Arrange (given)
        OwnID.CoreSDK.Init.Request(type: .register,
                           url: url,
                           sessionChallenge: "xcyHWNv1bsMEkVISvUr5H6s4cuylLI0gj-wykLaHQKI",
                           token: .none,
                           webLanguages: OwnID.CoreSDK.Languages.init(rawValue: []),
                           provider: MockAPI.badBodyProvider)
            //Act (when)
            .perform()
            .sink { completion in
                if case .failure(let error) = completion {
                    resultedError = error
                    expectation.fulfill()
                }
            } receiveValue: { value in
                XCTFail("\(value)")
            }
            .store(in: &bag)

        waitForExpectations(timeout: 2)
        
        //Assert (then)
        XCTAssertNotNil(resultedError)
    }
}
