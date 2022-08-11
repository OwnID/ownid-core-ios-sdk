import SwiftUI
import OwnIDCoreSDK

public extension OwnID.FlowsSDK {
    struct RegisterView: View, Equatable {
        public static func == (lhs: OwnID.FlowsSDK.RegisterView, rhs: OwnID.FlowsSDK.RegisterView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        
        @Binding private var usersEmail: String
        public var visualConfig: OwnID.UISDK.VisualLookConfig
        @ObservedObject public var viewModel: ViewModel
        
        private let shouldImmidiatelyShowTooltip: Bool
        
        public init(viewModel: ViewModel,
                    usersEmail: Binding<String>,
                    visualConfig: OwnID.UISDK.VisualLookConfig,
                    shouldImmidiatelyShowTooltip: Bool = false) {
            self.shouldImmidiatelyShowTooltip = shouldImmidiatelyShowTooltip
            self.viewModel = viewModel
            self._usersEmail = usersEmail
            self.visualConfig = visualConfig
            self.viewModel.getEmail = { usersEmail.wrappedValue }
        }
        
        public var body: some View {
            contents()
        }
    }
}

private extension OwnID.FlowsSDK.RegisterView {
    
    @ViewBuilder
    func contents() -> some View {
        switch viewModel.state {
        case .initial, .coreVM:
            skipPasswordView(state: .enabled)
            
        case .ownidCreated:
            skipPasswordView(state: .activated)
        }
    }
    
    func skipPasswordView(state: OwnID.UISDK.ButtonState) -> some View {
        let view = OwnID.UISDK.OwnIDView(viewState: .constant(state),
                                         visualConfig: visualConfig,
                                         shouldImmidiatelyShowTooltip: shouldImmidiatelyShowTooltip)
        viewModel.subscribe(to: view.eventPublisher)
        return view.eraseToAnyView()
    }
}
