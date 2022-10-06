import SwiftUI

public extension OwnID.FlowsSDK {
    struct LoginView: View, Equatable {
        public static func == (lhs: OwnID.FlowsSDK.LoginView, rhs: OwnID.FlowsSDK.LoginView) -> Bool {
            lhs.id == rhs.id
        }
        
        private let id = UUID()
        @Binding private var usersEmail: String
        public var visualConfig: OwnID.UISDK.VisualLookConfig
        
        @ObservedObject public var viewModel: ViewModel
        
        public init(viewModel: ViewModel,
                    usersEmail: Binding<String>,
                    visualConfig: OwnID.UISDK.VisualLookConfig) {
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

private extension OwnID.FlowsSDK.LoginView {
    
    @ViewBuilder
    func contents() -> some View {
        switch viewModel.state {
        case .initial, .coreVM:
            skipPasswordView(state: .enabled)
            
        case .loggedIn:
            skipPasswordView(state: .activated)
        }
    }
    
    func skipPasswordView(state: OwnID.UISDK.ButtonState) -> some View {
        let view = OwnID.UISDK.OwnIDView(viewState: .constant(state),
                                         visualConfig: visualConfig,
                                         shouldShowTooltip: $viewModel.shouldShowTooltip)
        viewModel.subscribe(to: view.eventPublisher)
        return view.eraseToAnyView()
    }
}
