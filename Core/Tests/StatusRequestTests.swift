import XCTest
import Combine
import TestsMocks
@testable import OwnIDCoreSDK

/// Tests show that for fixed input there is fixed output
final class StatusRequestTests: XCTestCase {
    //for each test case we have running new instance of XCTestCase, so we do not need to reset bag
    var bag = Set<AnyCancellable>()
    let context = "0u8ZCitQCUmkKKE6TK-w2A"
    let nonce = "pk132eorf--234"
    let sessionVerifier = "pk132eorf--234"
    var url: OwnID.CoreSDK.ServerURL {
        OwnID.CoreSDK.shared.statusURL(for: OwnID.CoreSDK.sdkName)
    }
    let string =
        """
        {
          "flowInfo": {
            "event": "login"
          },
          "metadata": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYmYiOjE2NDc5NjczOTMsImV4cCI6MTY0Nzk3NDU5MywiaWF0IjoxNjQ3OTY3MzkzLCJkYXRhIjp7ImFjdGlvbiI6IkxvZ2luIiwiYXV0aFR5cGUiOiJGSURPMiJ9fQ.E0ckfaVnsBxGvj2ARfJKDfTsbJe6tjfIDY-5LZPRxfJiUEaoFW7TwySdzKYFtTuxaH668tJT5nV_CmUlb3UGBAa-Uk5Kcd3uNwqG1P3TtlpH0SHROykqjHobNxzodgpzpvzW4RCWGP627SKLvyESC3lhbozrj4qGdjp-D5LjKyQkgNCw6nRLOOInOo06LAFiN71nsf4eEb60wKGof06haZYu-XODBs6p4X7-q7IPkt7vyYJNRGqDrBHWkcayv55MA3s15omyd6iMIKQ1270BcjgSTCwDjYY-VmGacwQKgWRQCkLpy_jQwhJgE3SW2CXKN_xnZP81cK6xdKKNwHv8gl_pZZRsyJi8YYLxkYhGiJ3WiP2SO0oPIBoJN3ScwV9D9hs4tL7Q268qulx7EuS7LNOh4OpmzPJHnFMgY22Pllo5dzkLD3Rh4koT9v2-bveyjlERJMKBjuaJO6bv0Y0g3fvBfRJ1o7IqBR6lRj2XSANJKvlL8Lqaf1Vg1hAWyysZymv7TY_bP2Zzv6jDT4RGGf7SCnm1kG_BphQOqJ30jV5kGG2R2kHvMC5VMmrPIX40VKSwBKZMmycSfryM-mOy4eq8qNAt7PG-kdWLsC8tWJNppBTSW_pgpDjxXXqtHx7nNzBxLecTU6wkgQqCRLYaxoPJHD-7xYyqCmmKtTVsFFs",
          "status": "finished",
          "context": "0u8ZCitQCUmkKKE6TK-w2A",
          "payload": {
            "type": "session",
            "data": {
              "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJkZW1vLXNlcnZlciIsInN1YiI6IjYyM2EwOWI5NDEwMjI5NDY4NzIyZmY5ZSIsImV4cCI6MTY0Nzk3NDU5MiwiaWF0IjoxNjQ3OTcwOTkyfQ.LOriz-nDb2yVe5BTItuk4KNYMhQamdfyQJnJ-iSWr5Y"
            }
          }
        }
        """
    
    override class func setUp() {
        OwnID.CoreSDK.shared.configureForTests()
    }
    
    func testStautusReqestCorrectBody() throws {
        let expectation = self.expectation(description: #function)
        var response: OwnID.CoreSDK.Payload?
        
        //Arrange (given)
        OwnID.CoreSDK.Status.Request(url: url,
                                     context: context,
                                     nonce: nonce,
                                     sessionVerifier: sessionVerifier,
                                     type: .login,
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
        
        //Assert (then)
        waitForExpectations(timeout: 2)
        XCTAssertNotNil(response)
    }
    
    func testStautusReqestError() throws {
        let expectation = self.expectation(description: #function)
        var resultedError: OwnID.CoreSDK.Error?
        
        //Arrange (given)
        OwnID.CoreSDK.Status.Request(url: url,
                                     context: context,
                                     nonce: nonce,
                                     sessionVerifier: sessionVerifier,
                                     type: .login,
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
        
        //Assert (then)
        waitForExpectations(timeout: 2)
        XCTAssertNotNil(resultedError)
    }
    
    func testStautusReqestBodyError() throws {
        let expectation = self.expectation(description: #function)
        var resultedError: OwnID.CoreSDK.Error?
        
        //Arrange (given)
        OwnID.CoreSDK.Status.Request(url: url,
                                     context: context,
                                     nonce: nonce,
                                     sessionVerifier: sessionVerifier,
                                     type: .login,
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
        
        //Assert (then)
        waitForExpectations(timeout: 2)
        XCTAssertNotNil(resultedError)
    }
}
