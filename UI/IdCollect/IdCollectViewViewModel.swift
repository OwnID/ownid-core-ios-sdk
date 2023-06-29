import Combine
import SwiftUI

extension OwnID.UISDK.IdCollect {
    final class ViewModel: ObservableObject {
        private var loginId = ""
        
        @Published var isLoading = false
        @Published var buttonState: OwnID.UISDK.ButtonState = .enabled
        @Published var isError = false
        private let store: Store<ViewState, Action>
        private let loginIdSettings: OwnID.CoreSDK.LoginIdSettings
        
        private var storeCancellable: AnyCancellable?
        private var bag = Set<AnyCancellable>()
        
        var titleKey: OwnID.CoreSDK.TranslationsSDK.TranslationKey {
            OwnID.CoreSDK.isPasskeysSupported ? .idCollectTitle : .idCollectNoBiometricsTitle(type: loginIdType.rawValue)
        }
        
        var messageKey: OwnID.CoreSDK.TranslationsSDK.TranslationKey {
            let type = loginIdType.rawValue
            return OwnID.CoreSDK.isPasskeysSupported ? .idCollectMessage(type: type) : .idCollectNoBiometricsMessage(type: type)
        }
        
        var loginIdType: OwnID.CoreSDK.LoginIdSettings.LoginIdType {
            return loginIdSettings.type ?? .email
        }
        
        init(store: Store<ViewState, Action>,
             loginId: String,
             loginIdSettings: OwnID.CoreSDK.LoginIdSettings) {
            self.store = store
            self.loginId = loginId
            self.loginIdSettings = loginIdSettings
            
            storeCancellable = store.$value
                .map { $0.isLoading }
                .sink { [weak self] isLoading in
                    self?.isLoading = isLoading
                }
            
            store.send(.viewLoaded)
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

            store.send(.loginIdEntered(loginId: loginId.value))
        }
    }
}
