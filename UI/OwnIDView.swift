import Foundation
import SwiftUI
import OwnIDCoreSDK

public extension OwnID.UISDK {
    struct OwnIDView: View {
        static func == (lhs: OwnID.UISDK.OwnIDView, rhs: OwnID.UISDK.OwnIDView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        private let isOrViewEnabled: Bool
        private let beakHeight: CGFloat = 8
        private let beakWidth: CGFloat = 14
        private let buttonOffset: CGFloat = 4
        private let textWithRegtangleHeight: CGFloat = 43
        
        private let imageButtonView: ImageButton
        private let coordinateSpaceName = String(describing: OwnID.UISDK.ImageButton.self)
        
        public var eventPublisher: OwnID.UISDK.EventPubliser {
            imageButtonView.eventPublisher
                .eraseToAnyPublisher()
        }
        
        public init(viewState: Binding<ButtonState>, visualConfig: VisualLookConfig) {
            self.imageButtonView = ImageButton(viewState: viewState, visualConfig: visualConfig)
            self.isOrViewEnabled = visualConfig.isOrViewEnabled
        }
        
        public var body: some View {
            HStack(spacing: 8) {
                if isOrViewEnabled {
                    OwnID.UISDK.OrView()
                }
                GeometryReader { geometryReader in
                    ZStack {
                        imageButtonView
                            .layoutPriority(1)
                            .coordinateSpace(name: coordinateSpaceName)
                        
                        Text("*")
                            .fixedSize()
                            .background(.green)
                            .offset(x: 0, y: -geometryReader.frame(in: .local).maxY)
                        Text("Login with FaceID / TouchID ede fe")
                            .fixedSize()
                            .background(.red)
                            .offset(x: -100, y: -80)
                    }
                }
            }
        }
    }
}
