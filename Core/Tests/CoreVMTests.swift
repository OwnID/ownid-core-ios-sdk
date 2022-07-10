import XCTest
import Combine
import MockSDK
@testable import OwnIDCoreSDK

/// Tests show that for fixed input there is fixed output
final class CoreVMTests: XCTestCase {
    //for each test case we have running new instance of XCTestCase, so we do not need to reset bag
    var bag = Set<AnyCancellable>()
    var coreVM: OwnID.CoreSDK.CoreViewModel!
    
    override class func setUp() {
        OwnID.CoreSDK.shared.configureForTests()
    }
    
    func testSuccessPath() throws {
        let expectation = self.expectation(description: #function)
        //Arrange (given)
        let session = APISessionStub(isInitSuccess: true, isStatusSuccess: true)
        coreVM = OwnID.CoreSDK.CoreViewModel(type: .register,
                                             email: .none,
                                             token: .none,
                                             session: session,
                                             sdkConfigurationName: OwnID.CoreSDK.sdkName,
                                             browserViewModelInitializer: { store, url in
            return BrowserOpenerMockViewModel(store: store, url: url)
        })
        //Act (when)
        coreVM.eventPublisher.sink { completion in
            if case .failure(let error) = completion {
                XCTFail(error.localizedDescription)
            }
        } receiveValue: { event in
            if case .success(let payload) = event {
                //Assert (then)
                guard payload.loginId == session.login,
                      payload.context == session.context,
                      payload.nonce == session.nonce else { XCTFail(); return }
                expectation.fulfill()
            }
        }
        .store(in: &bag)
        OwnID.CoreSDK.shared.subscribeForURL(coreViewModel: coreVM)
        coreVM.start()
        waitForExpectations(timeout: 4)
    }
}

extension CoreVMTests {
    final class BrowserOpenerMockViewModel: ObservableObject, BrowserOpener {
        private var store: Store<OwnID.CoreSDK.BrowserOpenerViewModel.State, OwnID.CoreSDK.BrowserOpenerViewModel.Action>
        
        init(store: Store<OwnID.CoreSDK.BrowserOpenerViewModel.State, OwnID.CoreSDK.BrowserOpenerViewModel.Action>, url: URL) {
            OwnID.CoreSDK.logger.logCore(.entry(Self.self))
            self.store = store
            let configName = store.value
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                OwnID.CoreSDK.shared.handle(url: URL(string: OwnID.CoreSDK.shared.redirectionURL(for: store.value))!, sdkConfigurationName: configName)
            }
        }
    }
}
