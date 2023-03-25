import SwiftUI
import Combine

public extension OwnID.UISDK {
    struct InstantConnectView<Content: View>: View {
        private let content: () -> Content
        private let emailPublisher: PassthroughSubject<String, Never>
        
        private let visualConfig: VisualLookConfig
        
        @Binding private var isLoading: Bool
        @Binding private var buttonState: ButtonState
        
        public init(emailPublisher: PassthroughSubject<String, Never>,
//                    viewState: Binding<ButtonState>,
                    visualConfig: VisualLookConfig,
//                    isLoading: Binding<Bool>,
                    @ViewBuilder content: @escaping () -> Content) {
            self.content = content
            self.emailPublisher = emailPublisher
            _isLoading = .constant(false)
            _buttonState = .constant(.enabled)
            self.visualConfig = visualConfig
        }
        
        @State private var email = ""
        
        private let resultPublisher = PassthroughSubject<Void, Never>()
        
        public var eventPublisher: OwnID.UISDK.EventPubliser {
            resultPublisher
                .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        
        public var body: some View {
            if #available(iOS 14.0, *) {
                ZStack {
                    content()
                    Image("closeImage", bundle: .resourceBundle)
                    Text("Sign In")
                    VStack {
                        Text("Enter your email")
                        TextField("", text: $email)
                            .background(Rectangle().fill(.gray))
                            .padding()
                        AuthButton(visualConfig: visualConfig,
                                   actionHandler: { resultPublisher.send(()) },
                                   isLoading: $isLoading,
                                   buttonState: $buttonState)
                        .padding()
                    }
                    .frame(height: 200)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(Rectangle().fill(.red))
                    .padding()
                }
                .onChange(of: email) { newValue in
                    emailPublisher.send(newValue)
                }
            } else {
                content()
            }
        }
    }
}
