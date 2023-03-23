import SwiftUI
import Combine

public extension OwnID.UISDK {
    struct InstantConnectView<Content: View>: View {
        private let content: () -> Content
        private let emailPublisher: PassthroughSubject<String, Never>
        public init(emailPublisher: PassthroughSubject<String, Never>, @ViewBuilder content: @escaping () -> Content) {
            self.content = content
            self.emailPublisher = emailPublisher
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
                    VStack {
                        TextField("", text: $email)
                            .background(Rectangle().fill(.gray))
                            .padding()
                        Button("Continue") {
                            resultPublisher.send(())
                        }
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
