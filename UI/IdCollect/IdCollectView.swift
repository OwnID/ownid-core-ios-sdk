import SwiftUI
import UIKit
import Combine

extension OwnID.UISDK {
    static func showIdCollectView(store: Store<OwnID.UISDK.IdCollect.ViewState, OwnID.UISDK.IdCollect.Action>,
                                  loginId: String,
                                  loginIdSettings: OwnID.CoreSDK.LoginIdSettings) {
        if #available(iOS 15.0, *) {
            let view = OwnID.UISDK.IdCollect.IdCollectView(store: store,
                                                                visualConfig: OwnID.UISDK.VisualLookConfig(),
                                                                loginId: loginId,
                                                                loginIdSettings: loginIdSettings,
                                                                closeClosure: {
                OwnID.UISDK.PopupManager.dismiss()
            })
            view.presentAsPopup()
        }
    }
}

extension OwnID.UISDK {
    enum IdCollect { }
}

extension OwnID.UISDK.IdCollect {
    @available(iOS 15.0, *)
    struct IdCollectView: Popup {
        private enum Constants {
            static let textFieldBorderWidth = 1.0
            static let titleFontSize = 20.0
            static let messageFontSize = 16.0
            static let emailFontSize = 18.0
            static let emailPadding = 10.0
            static let bottomPadding = 6.0
            static let publisherDebounce = 500
            static let closeImageName = "closeImage"
        }
        
        enum FocusField: Hashable {
            case email
        }
        
        public static func == (lhs: OwnID.UISDK.IdCollect.IdCollectView,
                               rhs: OwnID.UISDK.IdCollect.IdCollectView) -> Bool {
            lhs.uuid == rhs.uuid
        }
        private let uuid = UUID().uuidString
        private let loginIdPublisher = PassthroughSubject<String, Never>()
        
        private var visualConfig: OwnID.UISDK.VisualLookConfig
        private let closeClosure: () -> Void
        
        @ObservedObject var store: Store<ViewState, Action>
        @ObservedObject private var viewModel: ViewModel
        @FocusState private var focusedField: FocusField?
        @State private var loginId = ""
        private let loginIdSettings: OwnID.CoreSDK.LoginIdSettings

        private var bag = Set<AnyCancellable>()
        
        @State private var isTranslationChanged = false
        
        init(store: Store<ViewState, Action>,
             visualConfig: OwnID.UISDK.VisualLookConfig,
             loginId: String,
             loginIdSettings: OwnID.CoreSDK.LoginIdSettings,
             closeClosure: @escaping () -> Void) {
            self.store = store
            self.loginId = loginId
            self.loginIdSettings = loginIdSettings
            self.visualConfig = visualConfig
            self.closeClosure = closeClosure
            self.viewModel = ViewModel(store: store, loginId: loginId, loginIdSettings: loginIdSettings)
            
            viewModel.updateLoginIdPublisher(loginIdPublisher.eraseToAnyPublisher())
        }
        
        public func createContent() -> some View {
            viewContent()
                .onChange(of: loginId) { newValue in loginIdPublisher.send(newValue) }
                .onReceive(OwnID.CoreSDK.shared.translationsModule.translationsChangePublisher) {
                    isTranslationChanged.toggle()
                }
                .overlay {
                    if isTranslationChanged {
                        EmptyView()
                    }
                }
                .overlay(alignment: .topTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(Constants.closeImageName, bundle: .resourceBundle)
                    }
                    .padding(.trailing)
                    .padding(.top)
                }
        }
        
        public func backgroundOverlayTapped() {
            dismiss()
        }
        
        private func dismiss() {
            store.send(.cancel)
            closeClosure()
        }
        
        @ViewBuilder
        private func topSection() -> some View {
            HStack {
                Text(localizedKey: .emailCollectTitle)
                    .font(.system(size: Constants.titleFontSize))
                    .bold()
            }
            .padding(.top)
            .padding(.bottom, Constants.bottomPadding)
        }
        
        @ViewBuilder
        private func errorView() -> some View {
            if !viewModel.error.isEmpty {
                HStack {
                    Text(viewModel.error)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(OwnID.Colors.errorColor)
                        .padding(.bottom, Constants.bottomPadding)
                }
            }
        }
        
        @ViewBuilder
        private func viewContent() -> some View {
            VStack {
                topSection()
                VStack {
                    Text(localizedKey: .emailCollectMessage)
                        .font(.system(size: Constants.messageFontSize))
                        .foregroundColor(OwnID.Colors.otpContentMessageColor)
                        .padding(.bottom, Constants.bottomPadding)
                    errorView()
                    TextField("", text: $loginId)
                        .onChange(of: loginId) { _ in
                            viewModel.error = ""
                        }
                        .font(.system(size: Constants.emailFontSize))
                        .keyboardType(.emailAddress)
                        .focused($focusedField, equals: .email)
                        .padding(Constants.emailPadding)
                        .background(Rectangle().fill(OwnID.Colors.idCollectViewLoginFieldBackgroundColor))
                        .cornerRadius(cornerRadiusValue)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadiusValue)
                                .stroke(borderColor, lineWidth: Constants.textFieldBorderWidth)
                        )
                        .padding(.bottom, Constants.bottomPadding)
                        .padding(.top)
                    OwnID.UISDK.AuthButton(visualConfig: visualConfig,
                                           actionHandler: { viewModel.postLoginId() },
                                           isLoading: $viewModel.isLoading,
                                           buttonState: $viewModel.buttonState,
                                           translationKey: .stepsContinue)
                }
            }
            .padding()
            .onAppear() {
                focusedField = .email
            }
        }
        
        var borderColor: Color {
            if focusedField == .email {
                return OwnID.Colors.blue
            } else {
                return OwnID.Colors.idCollectViewLoginFieldBorderColor
            }
        }
    }
}

