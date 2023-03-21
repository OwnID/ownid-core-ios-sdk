import SwiftUI

public extension OwnID.FlowsSDK {
    struct RegisterView: View, Equatable {
        public static func == (lhs: OwnID.FlowsSDK.RegisterView, rhs: OwnID.FlowsSDK.RegisterView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        
        public var visualConfig: OwnID.UISDK.VisualLookConfig
        @ObservedObject public var viewModel: ViewModel
        
        public init(viewModel: ViewModel,
                    visualConfig: OwnID.UISDK.VisualLookConfig) {
            self.viewModel = viewModel
            self.visualConfig = visualConfig
            self.viewModel.currentMetadata = visualConfig.convertToCurrentMetric()
        }
        
        public var body: some View {
            skipPasswordView()
        }
    }
}

private extension OwnID.FlowsSDK.RegisterView {
    func skipPasswordView() -> some View {
        var config = visualConfig
        switch visualConfig.buttonViewConfig.variant {
        case .authButton:
            config.buttonViewConfig.variant = .iconButton(.faceId) // auth button is only available for login
            
        case .iconButton:
            break
        }
        let view = OwnID.UISDK.OwnIDView(viewState: .constant(viewModel.state.buttonState),
                                         visualConfig: config,
                                         shouldShowTooltip: $viewModel.shouldShowTooltip,
                                         isLoading: .constant(viewModel.state.isLoading))
        viewModel.subscribe(to: view.eventPublisher)
        return view.eraseToAnyView()
    }
}
