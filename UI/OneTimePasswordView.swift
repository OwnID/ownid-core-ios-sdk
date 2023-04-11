import SwiftUI
import UIKit
import Combine

extension OwnID.UISDK.OneTimePasswordView {
    struct ViewState: LoggingEnabled {
        let isLoggingEnabled: Bool
    }
    
    enum Action {
        case codeEntered(String)
        case cancel
        case emailIsNotRecieved
    }
}

extension OwnID.UISDK {
    static func showOTPView(store: Store<OwnID.UISDK.OneTimePasswordView.ViewState, OwnID.UISDK.OneTimePasswordView.Action>,
                            visualConfig: OwnID.UISDK.VisualLookConfig = .init()) {
        let view = OwnID.UISDK.OneTimePasswordView(store: store, visualConfig: visualConfig)
        if #available(iOS 15.0, *) {
            view.presentAsPopup()
        }
    }
}

#warning("need to pass error & loading events to this view when they occur")
#warning("pass visual config")
extension OwnID.UISDK {
    struct OneTimePasswordView: Popup {
        
        static func == (lhs: OwnID.UISDK.OneTimePasswordView, rhs: OwnID.UISDK.OneTimePasswordView) -> Bool {
            lhs.uuid == rhs.uuid
        }
        private let uuid = UUID().uuidString
        
        private var visualConfig: VisualLookConfig
        @State private var error = ""
        private let store: Store<ViewState, Action>
        
        init(store: Store<ViewState, Action>,
             visualConfig: VisualLookConfig) {
            self.visualConfig = visualConfig
            self.store = store
        }
        
        func createContent() -> some View {
            VStack {
                topSection()
                errorView()
                AuthButton(visualConfig: visualConfig,
                           actionHandler: { store.send(.codeEntered("1111")) },
                           isLoading: .constant(false),
                           buttonState: .constant(.enabled))
            }
        }
        
        @ViewBuilder
        private func topSection() -> some View {
            HStack {
                Text("Sign In With a One-time Code")
                    .font(.system(size: 20))
                    .bold()
                Spacer()
                Button {
                    if #available(iOS 15.0, *) {
                        OwnID.UISDK.PopupManager.dismiss()
                    }
                } label: {
                    Image("closeImage", bundle: .resourceBundle)
                }
            }
        }
        
        @ViewBuilder
        private func errorView() -> some View {
            if !error.isEmpty {
                HStack {
                    Text(error)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.red)
                        .padding(.bottom, 6)
                    Spacer()
                }
            }
        }
    }
}

@available(iOS 15.0, *)
extension OwnID.UISDK.OneTimePasswordView {
    static func viewModelReducer(state: inout OwnID.UISDK.OneTimePasswordView.ViewState, action: OwnID.UISDK.OneTimePasswordView.Action) -> [Effect<OwnID.UISDK.OneTimePasswordView.Action>] {
        switch action {
        case .codeEntered(_):
            return []
        case .cancel:
            return []
        case .emailIsNotRecieved:
            return []
        }
    }
}

@available(iOS 15.0, *)
extension OwnID.UISDK.OneTimePasswordView.Action: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .codeEntered(_):
            return "codeEntered"
        case .cancel:
            return "cancel"
        case .emailIsNotRecieved:
            return "emailIsNotRecieved"
        }
    }
}
