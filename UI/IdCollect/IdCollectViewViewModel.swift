import Combine

extension OwnID.UISDK.IdCollect {
    final class ViewModel: ObservableObject {
        private var loginId = ""
        
        @Published var isLoading = false
        @Published var buttonState: OwnID.UISDK.ButtonState = .enabled
        @Published var error = ""
        private let store: Store<ViewState, Action>
        private let loginIdSettings: OwnID.CoreSDK.LoginIdSettings
        
        private var bag = Set<AnyCancellable>()
        
        init(store: Store<ViewState, Action>,
             loginId: String,
             loginIdSettings: OwnID.CoreSDK.LoginIdSettings) {
            self.store = store
            self.loginId = loginId
            self.loginIdSettings = loginIdSettings
        }
        
        func updateLoginIdPublisher(_ loginIdPublisher: OwnID.CoreSDK.LoginIdPublisher) {
            loginIdPublisher.assign(to: \.loginId, on: self).store(in: &bag)
        }
        
        func postLoginId() {
            let loginId = OwnID.CoreSDK.LoginId(value: loginId, settings: loginIdSettings)

            if loginId.value.isEmpty || !loginId.isValid {
                error = loginId.error.errorDescription ?? ""
                return
            }
            
            isLoading = true
            store.send(.loginIdEntered(loginId: loginId.value))
        }
    }
}
