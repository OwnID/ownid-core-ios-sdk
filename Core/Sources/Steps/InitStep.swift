import Foundation
import Combine
import LocalAuthentication

extension OwnID.CoreSDK.CoreViewModel {
    class BaseStep {
        func run(state: inout State) -> [Effect<Action>] { return [] }
        
        func nextStepAction(_ step: OwnID.CoreSDK.Step) -> Action {
            let type = step.type
            switch type {
            case .fido2Authorize:
                return .fido2Authorize(step: step)
            case .starting:
                return .idCollect
            }
        }
        
        func errorEffect(_ error: OwnID.CoreSDK.CoreErrorLogWrapper) -> [Effect<Action>] {
            [Just(.error(error)).eraseToEffect()]
        }
        
        //error step
        
        //success step
    }
    
    class InitStep: BaseStep {
        private var bag = Set<AnyCancellable>()
        
        override func run(state: inout OwnID.CoreSDK.CoreViewModel.State) -> [Effect<Action>] {
            //TODO: get rid of this default LoginIdSettings
            let loginIdSettings = state.configuration?.loginIdSettings ?? OwnID.CoreSDK.LoginIdSettings(type: .email, regex: "")
            let loginId = OwnID.CoreSDK.LoginId(value: state.loginId, settings: loginIdSettings)
            
            if !loginId.value.isEmpty, !loginId.isValid {
                return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: loginId.error))
            }
            
            guard let configuration = state.configuration else {
                return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .localConfigIsNotPresent))
            }
            
            let session = state.apiSessionCreationClosure(configuration.initURL,
                                                          configuration.statusURL,
                                                          configuration.finalStatusURL,
                                                          configuration.authURL,
                                                          state.supportedLanguages)
            state.session = session

            let requestData = OwnID.CoreSDK.Init.RequestData(loginId: loginId.value,
                                                             type: state.type,
                                                             supportsFido2: OwnID.CoreSDK.isPasskeysSupported)
            return [sendInitialRequest(requestData: requestData, session: session)]
        }
        
        private func sendInitialRequest(requestData: OwnID.CoreSDK.Init.RequestData,
                                       session: APISessionProtocol) -> Effect<Action> {
            session.performInitRequest(requestData: requestData)
                .receive(on: DispatchQueue.main)
                .map { Action.initialRequestLoaded(response: $0) }
                .catch { Just(Action.error($0)) }
                .eraseToEffect()
        }
    }
    
    class FidoAuthStep: BaseStep {
        let step: OwnID.CoreSDK.Step
        
        init(step: OwnID.CoreSDK.Step) {
            self.step = step
        }
        
        override func run(state: inout OwnID.CoreSDK.CoreViewModel.State) -> [Effect<OwnID.CoreSDK.CoreViewModel.Action>] {
            let loginIdSettings = state.configuration?.loginIdSettings ?? OwnID.CoreSDK.LoginIdSettings(type: .email, regex: "")
            let loginId = OwnID.CoreSDK.LoginId(value: state.loginId, settings: loginIdSettings)
            
            guard let context = state.context else {
                print("contextIsMissing")
                return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .contextIsMissing))
            }
            
            guard let url = step.data.url else {
                return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .urlIsMissing))
            }
            
            if #available(iOS 16, *),
               let domain = step.data.relyingPartyId {
                let authManager = state.createAccountManagerClosure(state.authManagerStore, domain, state.context, url)
                switch state.type {
                case .register:
                    authManager.signUpWith(userName: state.loginId)
                case .login:
                    authManager.signInWith()
                }
                state.authManager = authManager
            } else {
                let vm = createBrowserVM(for: context,
                                         browserURL: url,
                                         loginId: loginId,
                                         sdkConfigurationName: state.sdkConfigurationName,
                                         store: state.browserViewModelStore,
                                         redirectionURLString: state.configuration?.redirectionURL,
                                         creationClosure: state.createBrowserOpenerClosure)
                state.browserViewModel = vm
            }
            
            return []
        }
    }
    
    class StopStep: BaseStep {
        override func run(state: inout OwnID.CoreSDK.CoreViewModel.State) -> [Effect<OwnID.CoreSDK.CoreViewModel.Action>] {
            let action = state.session.performStopRequest(url: state.stopUrl)
                .receive(on: DispatchQueue.main)
                .map { _ in Action.stopRequestLoaded }
                .catch { Just(Action.error($0)) }
                .eraseToEffect()
            
            return [action]
        }
    }
}

extension OwnID.CoreSDK {
    static var isPasskeysSupported: Bool {
        let isLeastPasskeysSupportediOS = ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 16, minorVersion: 0, patchVersion: 0))
        var isBiometricsAvailable = false
        let authContext = LAContext()
        let _ = authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch authContext.biometryType {
        case .none:
            break
        case .touchID:
            isBiometricsAvailable = true
        case .faceID:
            isBiometricsAvailable = true
        @unknown default:
            print("please update biometrics types")
        }
        let isPasscodeAvailable = LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        let isPasskeysSupported = isLeastPasskeysSupportediOS && (isBiometricsAvailable || isPasscodeAvailable)
        return isPasskeysSupported
    }
}
