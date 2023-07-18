import Foundation
import UIKit
import Combine
import AuthenticationServices

extension OwnID.CoreSDK {
    struct BrowserOpener {
        let cancelClosure: () -> Void
        
        func cancel() {
            cancelClosure()
        }
    }
}

extension OwnID.CoreSDK.BrowserOpener {
    typealias CreationClosure = (_ store: Store<OwnID.CoreSDK.BrowserOpenerViewModel.State, OwnID.CoreSDK.BrowserOpenerViewModel.Action>,
                                 _ url: URL,
                                 _ redirectionURL: OwnID.CoreSDK.RedirectionURLString) -> Self
    
    static var defaultOpener: CreationClosure {
        { store, url, redirectionURL in
            let vm = OwnID.CoreSDK.BrowserOpenerViewModel(store: store, url: url, redirectionURL: redirectionURL)
            return Self {
                vm.cancel()
            }
        }
    }
}

extension OwnID.CoreSDK.BrowserOpenerViewModel {
    typealias State = (String)
    enum Action {
        case viewCancelled
    }
}

extension OwnID.CoreSDK {
    final class BrowserOpenerViewModel: ObservableObject {
        private var store: Store<State, Action>
        private let authSessionContext = ASWebAuthenticationPresentationContext()
        private var cancellableSession: ASWebAuthenticationSession?
        
        init(store: Store<State, Action>, url: URL, redirectionURL: RedirectionURLString) {
            self.store = store
            startAuthSession(url: url, redirectionURL: redirectionURL)
        }
        
        func cancel() {
            cancellableSession?.cancel()
        }
        
        private func startAuthSession(url: URL, redirectionURL: RedirectionURLString) {
            if let schemeURL = URL(string: redirectionURL) {
                let configName = store.value
                let session = ASWebAuthenticationSession(url: url, callbackURLScheme: .none)
                { [weak self] _, error in
                    if let errorAuth = error as? ASWebAuthenticationSessionError,
                       case .canceledLogin = errorAuth.code {
                        self?.store.send(.viewCancelled)
                    } else {
                        OwnID.CoreSDK.logger.log(level: .debug, message: "Session finish", Self.self)
                        OwnID.CoreSDK.shared.handle(url: schemeURL, sdkConfigurationName: configName)
                    }
                }
                cancellableSession = session
                session.presentationContextProvider = authSessionContext
                session.start()
                OwnID.CoreSDK.logger.log(level: .debug, message: "Session start", Self.self)
            } else {
                store.send(.viewCancelled)
            }
        }
    }
}
