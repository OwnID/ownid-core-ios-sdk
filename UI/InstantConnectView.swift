import SwiftUI
import Combine

public extension OwnID.UISDK {
    struct InstantConnectView<Content: View>: View {
        private let content: () -> Content
        public init(emailPublisher: PassthroughSubject<String, Never>, @ViewBuilder content: @escaping () -> Content) {
            self.content = content
            _email = Binding(get: { return "" }, set: { value, _ in
                emailPublisher.send(value)
            })
        }
        
        @Binding private var email: String
        
        private let resultPublisher = PassthroughSubject<Void, Never>()
        
        public var eventPublisher: OwnID.UISDK.EventPubliser {
            resultPublisher
                .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        
        public var body: some View {
            ZStack {
                content()
                Group {
                    TextField("", text: $email)
                }
            }
        }
    }
}
