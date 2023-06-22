import Combine

extension OwnID.UISDK.IdCollect {
    final class ViewModel: ObservableObject {
        private var loginId = ""
        
        @Published var isLoading = false
        @Published var buttonState: OwnID.UISDK.ButtonState = .enabled
        @Published var isError = false
        private let store: Store<ViewState, Action>
        private let loginIdSettings: OwnID.CoreSDK.LoginIdSettings
        
        private var bag = Set<AnyCancellable>()
        
        var titleKey: OwnID.CoreSDK.TranslationsSDK.TranslationKey {
            OwnID.CoreSDK.isPasskeysSupported ? .idCollectTitle : .idCollectNoBiometricsTitle(type: loginIdSettings.type.rawValue)
        }
        
        var messageKey: OwnID.CoreSDK.TranslationsSDK.TranslationKey {
            let loginIdType = loginIdSettings.type.rawValue
            return OwnID.CoreSDK.isPasskeysSupported ? .idCollectMessage(type: loginIdType) : .idCollectNoBiometricsMessage(type: loginIdType)
        }
        
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
                isError = true
                return
            }
            
            isLoading = true
            store.send(.loginIdEntered(loginId: loginId.value))
        }
    }
}
