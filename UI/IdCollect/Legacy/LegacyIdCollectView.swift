
import SwiftUI
import Combine

extension OwnID.UISDK.IdCollect {
    struct LegacyIdCollectView: Popup {
        private enum Constants {
            static let padding = 22.0
            static let closeTopPadding = 12.0
            static let closeTrailingPadding = 10.0
            static let titleTopPadding = 10.0
            static let titleSidePadding = 26.0
            static let textFieldTopPadding = 20.0
            static let emailPadding = 10.0
            static let bottomPadding = 8.0
            
            static let textFieldHeight = 22.0
            static let textFieldBorderWidth = 1.0
            static let errorViewHeight = 28.0
            static let errorViewCornerRadius = 4.0
            
            static let titleFontSize = 20.0
            static let messageFontSize = 16.0
            static let emailFontSize = 16.0
            static let errorFontSize = 12.0
            
            static let publisherDebounce = 500
            
            static let closeImageName = "closeImage"
        }
        
        enum FocusField: Hashable {
            case email
        }
        
        public static func == (lhs: OwnID.UISDK.IdCollect.LegacyIdCollectView,
                               rhs: OwnID.UISDK.IdCollect.LegacyIdCollectView) -> Bool {
            lhs.uuid == rhs.uuid
        }
        private let uuid = UUID().uuidString
        private let loginIdPublisher = PassthroughSubject<String, Never>()
        
        private var visualConfig: OwnID.UISDK.VisualLookConfig
        private let closeClosure: () -> Void
        
        @ObservedObject var store: Store<ViewState, Action>
        @ObservedObject private var viewModel: ViewModel
        @State private var focusedField: FocusField?
        @State private var loginId = ""
        private let loginIdSettings: OwnID.CoreSDK.LoginIdSettings

        private var bag = Set<AnyCancellable>()
        
        @State private var isTranslationChanged = false
        
        private var placeholder: String {
            OwnID.CoreSDK.TranslationsSDK.TranslationKey.idCollectPlaceholder(type: viewModel.loginIdType.rawValue).localized()
        }
        
        private var cancel: String {
            OwnID.CoreSDK.TranslationsSDK.TranslationKey.stepsCancel.localized()
        }
        
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
        
        private func closeButton() -> some View {
            Button {
                dismiss()
            } label: {
                Image(Constants.closeImageName, bundle: .resourceBundle)
            }
            .modifier(AccessibilityLabelModifier(accessibilityLabel: cancel))
            .padding(.trailing, Constants.closeTrailingPadding)
            .padding(.top, Constants.closeTopPadding)
        }
        
        @ViewBuilder
        private func emptyTranslationView() -> some View {
            if isTranslationChanged {
                EmptyView()
            }
        }
        
        public func createContent() -> some View {
            Group {
                viewContent()
                    .onChange(of: loginId) { newValue in loginIdPublisher.send(newValue) }
                    .onReceive(OwnID.CoreSDK.shared.translationsModule.translationsChangePublisher) {
                        isTranslationChanged.toggle()
                    }
                    .modifier(Overlay(view: emptyTranslationView()))
                    .modifier(Overlay(view: closeButton(), alignment: .topTrailing))
            }
            .environment(\.layoutDirection, OwnID.CoreSDK.shared.translationsModule.isRTLLanguage ? .rightToLeft : .leftToRight)
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
                Text(localizedKey: viewModel.titleKey)
                    .font(.system(size: Constants.titleFontSize))
                    .bold()
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Constants.titleTopPadding)
            .padding([.leading, .trailing], Constants.titleSidePadding)
            .padding(.bottom, Constants.bottomPadding)
        }
        
        @ViewBuilder
        private func errorView() -> some View {
            if store.value.error != nil {
                Text(localizedKey: .stepsError)
                    .font(.system(size: Constants.errorFontSize))
                    .frame(maxWidth: .infinity)
                    .frame(height: Constants.errorViewHeight)
                    .foregroundColor(.white)
                    .background(RoundedRectangle(cornerRadius: Constants.errorViewCornerRadius))
            }
        }
        
        @ViewBuilder
        private func errorText() -> some View {
            if viewModel.isError {
                HStack {
                    Text(localizedKey: .idCollectError(type: viewModel.loginIdType.rawValue))
                        .multilineTextAlignment(.center)
                        .foregroundColor(OwnID.Colors.errorColor)
                        .padding(.bottom, Constants.bottomPadding)
                }
            }
        }
        
        @ViewBuilder
        private func continueButton() -> some View {
            if !store.value.isFlowFinished {
                OwnID.UISDK.AuthButton(visualConfig: visualConfig,
                                       actionHandler: { viewModel.postLoginId() },
                                       isLoading: $viewModel.isLoading,
                                       buttonState: $viewModel.buttonState,
                                       translationKey: .idCollectContinue(type: viewModel.loginIdType.rawValue))
            }
        }
        
        @ViewBuilder
        private func viewContent() -> some View {
            VStack {
                topSection()
                VStack {
                    Text(localizedKey: viewModel.messageKey)
                        .font(.system(size: Constants.messageFontSize))
                        .foregroundColor(OwnID.Colors.popupContentMessageColor)
                        .padding(.bottom, Constants.bottomPadding)
                    errorText()
                    FocusedTextField(text: $loginId, focusedField: $focusedField, equals: .email, configuration: { textField in
                        textField.placeholder = placeholder
                        textField.keyboardType = .emailAddress
                        textField.autocapitalizationType = .none
                        textField.autocorrectionType = .no
                        textField.font = UIFont.systemFont(ofSize: Constants.emailFontSize)
                    })
                    .frame(height: Constants.textFieldHeight)
                        .onChange(of: loginId) { _ in
                            viewModel.isError = false
                        }
                        .padding(Constants.emailPadding)
                        .background(Rectangle().fill(OwnID.Colors.idCollectViewLoginFieldBackgroundColor))
                        .cornerRadius(cornerRadiusValue)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadiusValue)
                                .stroke(borderColor, lineWidth: Constants.textFieldBorderWidth)
                        )
                        .padding(.top, Constants.textFieldTopPadding)
                        .padding(.bottom, Constants.bottomPadding)
                        continueButton()
                    .padding(.bottom, Constants.bottomPadding)
                    errorView()
                }
            }
            .padding(.all, Constants.padding)
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

