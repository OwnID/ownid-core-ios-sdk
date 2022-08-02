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
        
        @State private var textOffsetFromScreenSide: CGFloat = 0
        
        public var body: some View {
            HStack(spacing: 8) {
                if isOrViewEnabled {
                    OwnID.UISDK.OrView()
                }
                    ZStack {
                        imageButtonView
                            .layoutPriority(1)
                            .coordinateSpace(name: coordinateSpaceName)
                        Text("⬇️")
                            .fixedSize()
                            .background(.green)
                            .offset(x: 0, y: -50)
                        Text("Login with FaceID / TouchID start of the best")
                            .fixedSize()
                            .background(.red)
                            .offset(x: textOffsetFromScreenSide, y: 0)
                            .background(BackgroundGeometry())
                            .onPreferenceChange(GeometryFramePreferenceKey.self, perform: { textOffsetFromScreenSide = calculateSpacingDistance(viewFrame: $0) })
                    }
            }
        }
        
        private func calculateSpacingDistance(viewFrame: CGRect) -> CGFloat {
            if viewFrame.maxX >= UIScreen.main.bounds.size.width {
                let spacingToScreenSide: CGFloat = 10
                let offsetFromScreenSide = UIScreen.main.bounds.size.width - viewFrame.maxX
                return offsetFromScreenSide - spacingToScreenSide
            }
            return 0
        }
    }
}

struct GeometryFramePreferenceKey: PreferenceKey {
    static var defaultValue = CGRect()

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }

    typealias Value = CGRect
}

struct BackgroundGeometry: View {
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(.clear)
                .preference(key: GeometryFramePreferenceKey.self, value: geometry.frame(in: .global))
        }
    }
}
