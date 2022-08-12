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
        
        /// In oerder to make our overlay dismiss properly, we need to somewhere store the value of the binding.
        /// if we simply use `Binding(get: { true }, set: { _ in })` as default value, it is not possible to
        /// write values there. It is a problem here, as we need to dismiss `fullScreenCover`,
        /// we need to write to binding some `false` value. If we have empty set binding closure,
        /// value is not persisted in UI build system. For this to work, we use simple `@State`
        /// as default value, where property can be written to and `fullScreenCover` dissmissed.
        @State var defaultShouldImmidiatelyShowTooltip = true
        private let shouldImmidiatelyShowTooltip: Binding<Bool>?
        
        public init(viewModel: ViewModel,
                    usersEmail: Binding<String>,
                    visualConfig: OwnID.UISDK.VisualLookConfig,
                    shouldImmidiatelyShowTooltip: Binding<Bool>?) {
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
                                         shouldImmidiatelyShowTooltip: (shouldImmidiatelyShowTooltip != nil) ? shouldImmidiatelyShowTooltip! : $defaultShouldImmidiatelyShowTooltip)
        viewModel.subscribe(to: view.eventPublisher)
        return view.eraseToAnyView()
    }
}
