import SwiftUI
import UIKit
import Combine

extension OwnID.UISDK {
    @available(iOS 15.0, *)
    struct PopupView: View {
        @StateObject private var stack: PopupManager = .shared
        
        var body: some View {
            if let view = stack.views.first {
                PopupStackView(popupContent: view)
                    .background(createOverlay()
                        .onTapGesture {
                            view.backgroundOverlayTapped()
                        })
            } else {
                EmptyView()
            }
        }
    }
}

extension OwnID.UISDK {
    @available(iOS 15.0, *)
    struct PopupStackView: View {
        private enum Constants {
            static let contentCornerRadius: CGFloat = 9
            static let animationResponse = 0.32
            static let animationDampingFraction = 1.0
            static let animationDuration = 0.32
        }
        
        @Environment(\.colorScheme) var colorScheme
        
        let popupContent: AnyPopup
        var body: some View {
            VStack(spacing: 0) {
                Spacer()
                ZStack(alignment: .bottom) {
                    popupContent.createContent()
                        .background(colorScheme == .dark ? .regularMaterial : .thinMaterial,
                                    in: RoundedCorner(radius: Constants.contentCornerRadius, corners: [.topLeft, .topRight]))
                        .onTapGesture {
                            //TODO: reimplement it using @FocusState
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .transition(.move(edge: .top))
                }
                //To apply the thin material style on bottom safe area since ignoresSafeArea() doesn't work properly
                ZStack {
                    Color(.clear)
                        .background(colorScheme == .dark ? .regularMaterial : .thinMaterial)
                }
                .frame(height: 0)
                .ignoresSafeArea()
            }
            .animation(.spring(response: Constants.animationResponse,
                               dampingFraction: Constants.animationDampingFraction,
                               blendDuration: Constants.animationDuration),
                       value: popupContent)
        }
    }
}

@available(iOS 15.0, *)
public extension View {
    func addInstantOverlayView() -> some View {
        overlay(OwnID.UISDK.PopupView())
    }
}

@available(iOS 15.0, *)
extension UIScreen {
    static let width: CGFloat = main.bounds.size.width
    static let height: CGFloat = main.bounds.size.height
    static let safeArea: UIEdgeInsets = {
        UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .map({ $0 as? UIWindowScene })
            .compactMap({ $0 })
            .first?.windows
            .filter({ $0.isKeyWindow })
            .first?
            .safeAreaInsets ?? .zero
    }()
}

public extension OwnID.UISDK {
    final class PopupManager: ObservableObject {
        @Published var views = [OwnID.UISDK.AnyPopup]()
        
        public var visualLookConfig = OTPViewConfig()
        public static let shared: PopupManager = .init()
        private init() {}
    }
}

public protocol Popup: View, Hashable, Equatable {
    associatedtype V: View

    var id: String { get }

    func createContent() -> V
    func backgroundOverlayTapped()
}

public extension Popup {
    func presentAsPopup() { OwnID.UISDK.PopupManager.present(OwnID.UISDK.AnyPopup(self)) }
    func dismiss() { OwnID.UISDK.PopupManager.dismiss() }

    static func ==(lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var body: V { createContent() }
    var id: String { String(describing: type(of: self)) }
}

extension OwnID.UISDK {
    struct AnyPopup: Popup {
        let id: String
        private let popup: any Popup
        
        init(_ popup: some Popup) {
            self.popup = popup
            self.id = popup.id
        }
        
        func backgroundOverlayTapped() {
            popup.backgroundOverlayTapped()
        }
    }
}

extension OwnID.UISDK.AnyPopup {
    func createContent() -> some View {
        AnyView(popup)
    }
}

extension OwnID.UISDK.PopupManager {
    static func present(_ popup: OwnID.UISDK.AnyPopup) {
        DispatchQueue.main.async {
            withAnimation(nil) {
                shared.views.append(popup)
            }
        }
    }
    
    public static func dismiss() { shared.views.removeAll() }
}

@available(iOS 15.0, *)
private extension OwnID.UISDK.PopupView {
    var overlayColour: Color { .black.opacity(0.05) }
    var overlayAnimation: Animation { .easeInOut }
}

@available(iOS 15.0, *)
private extension OwnID.UISDK.PopupView {
    func createOverlay() -> some View {
        overlayColour
            .ignoresSafeArea()
            .animation(overlayAnimation, value: true)
    }
}
