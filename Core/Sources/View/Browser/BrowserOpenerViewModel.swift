import Foundation
import UIKit
import Combine
import AuthenticationServices

protocol BrowserOpener: AnyObject {
    init(store: Store<OwnID.CoreSDK.BrowserOpenerViewModel.State, OwnID.CoreSDK.BrowserOpenerViewModel.Action>, url: URL)
}

extension OwnID.CoreSDK.BrowserOpenerViewModel {
    typealias State = (String)
    enum Action {
        case viewCancelled
    }
}

extension OwnID.CoreSDK {
    final class BrowserOpenerViewModel: ObservableObject, BrowserOpener {
        private var store: Store<State, Action>
        private let authSessionContext = ASWebAuthenticationPresentationContext()
        
        init(store: Store<State, Action>, url: URL) {
            self.store = store
            startAuthSession(url: url)
        }
        
        private func startAuthSession(url: URL) {
            if let schemeURL = URL(string: OwnID.CoreSDK.shared.redirectionURL(for: store.value)) {
                let configName = store.value
                let session = ASWebAuthenticationSession(url: url, callbackURLScheme: .none)
                { [weak self] _, error in
                    if let errorAuth = error as? ASWebAuthenticationSessionError,
                       case .canceledLogin = errorAuth.code {
                        self?.store.send(.viewCancelled)
                    } else {
                        OwnID.CoreSDK.logger.logCore(.entry(message: "Session finish", Self.self))
                        OwnID.CoreSDK.shared.handle(url: schemeURL, sdkConfigurationName: configName)
                    }
                }
                session.presentationContextProvider = authSessionContext
                session.start()
                OwnID.CoreSDK.logger.logCore(.entry(message: "Session start", Self.self))
            } else {
                store.send(.viewCancelled)
            }
        }
    }
}
