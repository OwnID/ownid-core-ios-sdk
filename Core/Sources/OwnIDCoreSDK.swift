import SwiftUI
import Combine

public extension OwnID.CoreSDK {
    static let sdkName = String(describing: OwnID.CoreSDK.self)
    static let version = "1.0.1"
    static let APIVersion = "1"
}

/// OwnID class represents core part of SDK. It performs initialization and creates views. It reads OwnIDConfiguration from disc, parses it and loads to memory for later usage. It is a singleton so the URL returned from browser can be linked to corresponding view.
public extension OwnID {
    
    static func startDebugConsoleLogger() {
        OwnID.CoreSDK.logger.add(OwnID.CoreSDK.ConsoleLogger())
    }
    
    final class CoreSDK {
        fileprivate var serverURL: ServerURL {
            getConfiguration(for: configurationName).ownIDServerURL
        }
        
        public static let shared = CoreSDK()
        public let translationsModule = TranslationsSDK.Manager()
        @ObservedObject var store: Store<SDKState, SDKAction>
        
        private let urlPublisher = PassthroughSubject<Void, Error>()
        
        private init() {
            let store = Store(
                initialValue: SDKState(),
                reducer: with(
                    OwnID.CoreSDK.coreReducer,
                    logging
                )
            )
            self.store = store
        }
        
        var configurationName: String {
            store.value.configurationName
        }
        
        public static var logger: LoggerProtocol {
            Logger.shared
        }
        
        public func configureForTests() {
            store.send(.configureForTests)
        }
        
        public func configure(userFacingSDK: SDKInformation, underlyingSDKs: [SDKInformation]) {
            store.send(.configureFromDefaultConfiguration(userFacingSDK: userFacingSDK, underlyingSDKs: underlyingSDKs))
        }
        
        func subscribeForURL(coreViewModel: CoreViewModel) {
            coreViewModel.subscribeToURL(publisher: urlPublisher.eraseToAnyPublisher())
        }
        
        public func configure(appID: String, redirectionURL: String, userFacingSDK: SDKInformation, underlyingSDKs: [SDKInformation], environment: String? = .none) {
            store.send(.configure(appID: appID,
                                  redirectionURL: redirectionURL,
                                  userFacingSDK: userFacingSDK,
                                  underlyingSDKs: underlyingSDKs,
                                  isTestingEnvironment: false,
                                  environment: environment))
        }
        
        public func configureFor(plistUrl: URL, userFacingSDK: SDKInformation, underlyingSDKs: [SDKInformation]) {
            store.send(.configureFrom(plistUrl: plistUrl, userFacingSDK: userFacingSDK, underlyingSDKs: underlyingSDKs))
        }
        
        func getConfiguration(for sdkConfigurationName: String) -> Configuration {
            store.value.getConfiguration(for: sdkConfigurationName)
        }
        
        /// Starts registration flow
        /// - Parameters:
        ///   - email: Used in plugin SDKs to find identity in web app FIDO2 storage and to display it for login
        ///   - sdkConfigurationName: Name of current running SDK
        ///   - webLanguages: Languages for web view. List of well-formed [IETF BCP 47 language tag](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Language) .
        /// - Returns: View that is presented in sheet
        public func createCoreViewModelForRegister(email: Email? = .none,
                                                   sdkConfigurationName: String,
                                                   webLanguages: OwnID.CoreSDK.Languages) -> CoreViewModel {
            let session = apiSession(configurationName: sdkConfigurationName, webLanguages: webLanguages)
            let viewModel = CoreViewModel(type: .register,
                                          email: email,
                                          token: .none,
                                          session: session,
                                          sdkConfigurationName: sdkConfigurationName)
            viewModel.subscribeToURL(publisher: urlPublisher.eraseToAnyPublisher())
            return viewModel
        }
        
        /// Starts login flow
        /// - Parameters:
        ///   - email: Used in plugin SDKs to find identity in web app FIDO2 storage and to display it for login
        ///   - sdkConfigurationName: Name of current running SDK
        ///   - webLanguages: Languages for web view. List of well-formed [IETF BCP 47 language tag](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Language) .
        /// - Returns: View that is presented in sheet
        public func createCoreViewModelForLogIn(email: Email? = .none,
                                                sdkConfigurationName: String,
                                                webLanguages: OwnID.CoreSDK.Languages) -> CoreViewModel {
            let session = apiSession(configurationName: sdkConfigurationName, webLanguages: webLanguages)
            let viewModel = CoreViewModel(type: .login,
                                          email: email,
                                          token: .none,
                                          session: session,
                                          sdkConfigurationName: sdkConfigurationName)
            viewModel.subscribeToURL(publisher: urlPublisher.eraseToAnyPublisher())
            return viewModel
        }
        
        func apiSession(configurationName: String, webLanguages: OwnID.CoreSDK.Languages) -> APISessionProtocol {
            return APISession(serverURL: serverURL(for: configurationName), statusURL: statusURL(for: configurationName), webLanguages: webLanguages)
        }
        
        /// Used to handle the redirects from browser after webapp is finished
        /// - Parameter url: URL returned from webapp after it has finished
        /// - Parameter sdkConfigurationName: Used to get proper data from configs in case of multiple SDKs
        public func handle(url: URL, sdkConfigurationName: String) {
            OwnID.CoreSDK.logger.logCore(.entry(message: "\(url.absoluteString)", Self.self))
            let redirectParamKey = "redirect"
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            let redirectParameterValue = components?.first(where: { $0.name == redirectParamKey })?.value
            if redirectParameterValue == "false" {
                urlPublisher.send(completion: .failure(.redirectParameterFromURLCancelledOpeningSDK))
                return
            }
            
            guard url
                .absoluteString
                .lowercased()
                .starts(with: getConfiguration(for: sdkConfigurationName)
                    .redirectionURL
                    .lowercased())
            else {
                urlPublisher.send(completion: .failure(.notValidRedirectionURLOrNotMatchingFromConfiguration))
                return
            }
            urlPublisher.send(())
        }
    }
}

public extension OwnID.CoreSDK {
    func statusURL(for sdkConfigurationName: String) -> ServerURL {
        getConfiguration(for: sdkConfigurationName).statusURL
    }
}

public extension OwnID.CoreSDK {
    var environment: String? {
        getConfiguration(for: configurationName).environment
    }
    
    var metricsURL: ServerURL {
        serverURL.deletingLastPathComponent().appendingPathComponent("events")
    }
}
