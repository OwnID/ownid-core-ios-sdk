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
            case .success:
                return .success
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
            
            guard let url = step.data?.url else {
                return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .urlIsMissing))
            }
            
            if #available(iOS 16, *),
               let domain = step.data?.relyingPartyId {
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
        
        func sendAuthRequest(state: inout OwnID.CoreSDK.CoreViewModel.State,
                             fido2Payload: Encodable) -> [Effect<Action>] {
            guard let urlString = step.data?.url, let url = URL(string: urlString) else {
                return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .urlIsMissing))
            }
            
            return [state.session.performAuthRequest(url: url, fido2Payload: fido2Payload, context: state.context)
                .receive(on: DispatchQueue.main)
                .map { [self] in nextStepAction($0.step) }
                .catch { Just(Action.authManagerRequestFail(error: $0, browserBaseURL: urlString)) }
                .eraseToEffect()]
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
    
    class FinalStep: BaseStep {
        override func run(state: inout OwnID.CoreSDK.CoreViewModel.State) -> [Effect<OwnID.CoreSDK.CoreViewModel.Action>] {
            let requestLanguage = state.supportedLanguages.rawValue.first
            let action = state.session.performFinalStatusRequest(url: state.finalUrl, context: state.context)
                .receive(on: DispatchQueue.main)
                .map { response in
                    let payload = OwnID.CoreSDK.Payload(dataContainer: response.payload.data,
                                                        metadata: response.metadata,
                                                        context: response.context,
                                                        loginId: response.payload.loginId,
                                                        responseType: OwnID.CoreSDK.StatusResponseType(rawValue: response.payload.type ?? "") ?? .registrationInfo,
                                                        authType: response.flowInfo.authType,
                                                        requestLanguage: requestLanguage)
                    return payload
                }
                .map { Action.statusRequestLoaded(response: $0) }
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
