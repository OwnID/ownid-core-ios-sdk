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
            self.viewModel.currentMetadata = visualConfig.convertToCurrentMetric()
        }
        
        public var body: some View {
            skipPasswordView()
        }
    }
}

private extension OwnID.FlowsSDK.LoginView {
    func skipPasswordView() -> some View {
        let view = OwnID.UISDK.OwnIDView(viewState: .constant(viewModel.state.buttonState),
                                         visualConfig: visualConfig,
                                         shouldShowTooltip: $viewModel.shouldShowTooltip,
                                         isLoading: .constant(viewModel.state.isLoading))
        viewModel.subscribe(to: view.eventPublisher)
        return view.eraseToAnyView()
    }
}
