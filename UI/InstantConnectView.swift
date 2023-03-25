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
            if #available(iOS 15.0, *) {
                content()
                    .overlay(alignment: .bottom, content: {
                        GeometryReader { geometry in
                            VStack {
                                HStack {
                                    Text("Sign In")
                                    Spacer()
                                    Image("closeImage", bundle: .resourceBundle)
                                }
                                VStack {
                                    Text("Enter your email")
                                    TextField("", text: $email)
                                        .background(Rectangle().fill(.white))
                                        .padding()
                                    AuthButton(visualConfig: visualConfig,
                                               actionHandler: { resultPublisher.send(()) },
                                               isLoading: $isLoading,
                                               buttonState: $buttonState)
                                    .padding()
                                }
                            }
                            .background(Rectangle().fill(.gray))
                            .offset(x: -geometry.frame(in: .global).origin.x, y: -geometry.frame(in: .global).origin.y)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        }
                    })
                    .onChange(of: email) { newValue in
                        emailPublisher.send(newValue)
                    }
            } else {
                content()
            }
        }
    }
}
