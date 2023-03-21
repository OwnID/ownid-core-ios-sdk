import SwiftUI
import Combine

public extension OwnID.UISDK {
    struct InstantConnectView: View {
        public init(emailPublisher: PassthroughSubject<String, Never>) {
            _email = Binding(get: { return "" }, set: { value, _ in
                emailPublisher.send(value)
            })
            convert publisher to binding
        }
        
        @Binding private var email: String
        
        private let resultPublisher = PassthroughSubject<Void, Never>()
        
        public var eventPublisher: OwnID.UISDK.EventPubliser {
            resultPublisher
                .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        
        public var body: some View {
            TextField("", text: $email)
        }
    }
}
