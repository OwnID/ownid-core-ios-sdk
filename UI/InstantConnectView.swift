import SwiftUI
import UIKit
import Combine

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
            .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow})
            .first?
            .safeAreaInsets ?? .zero
    }()
}

@available(iOS 15.0, *)
extension View {
    func alignToBottom(_ value: CGFloat = 0) -> some View {
        VStack(spacing: 0) {
            Spacer()
            self
            Spacer.height(value)
        }
    }
}

@available(iOS 15.0, *)
extension Spacer {
    @ViewBuilder static func height(_ value: CGFloat?) -> some View {
        switch value {
            case .some(let value): Spacer().frame(height: max(value, 0))
            case nil: Spacer()
        }
    }
}

extension OwnID.UISDK {
    @available(iOS 15.0, *)
    struct PopupStackView: View {
        let popupContent: OwnID.UISDK.InstantConnectView
        var body: some View {
            ZStack(alignment: .bottom) {
                popupContent
                    .background(.white)
                    .transition(.move(edge: .top))
            }
            .ignoresSafeArea()
            .alignToBottom()
            .animation(.spring(response: 0.32, dampingFraction: 1, blendDuration: 0.32), value: popupContent)
        }
    }
}

public extension OwnID.UISDK {
    @available(iOS 15.0, *)
    class PopupManager: ObservableObject {
        @Published var views = [OwnID.UISDK.InstantConnectView]()
        
        public static let shared: PopupManager = .init()
        private init() {}
    }
}

@available(iOS 15.0, *)
extension OwnID.UISDK.PopupManager {
    public static func present(_ popup: OwnID.UISDK.InstantConnectView) { DispatchQueue.main.async { withAnimation(nil) {
        shared.views.append(popup)
    }}}
    
    public static func dismiss() { shared.views.removeAll() }
}

extension OwnID.UISDK {
    @available(iOS 15.0, *)
    struct PopupView: View {
        @StateObject private var stack: PopupManager = .shared
        
        var body: some View {
            if let view = stack.views.first {
                PopupStackView(popupContent: view)
                    .frame(width: UIScreen.width, height: UIScreen.height)
                    .background(createOverlay())
            } else {
                EmptyView()
            }
        }
    }
}

@available(iOS 15.0, *)
private extension OwnID.UISDK.PopupView {
    var overlayColour: Color { .black.opacity(0.44) }
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

public extension OwnID.UISDK {
    struct InstantConnectView: View, Equatable {
        public static func == (lhs: OwnID.UISDK.InstantConnectView, rhs: OwnID.UISDK.InstantConnectView) -> Bool {
            lhs.uuid == rhs.uuid
        }
        private let uuid = UUID().uuidString
        private let emailPublisher = PassthroughSubject<String, Never>()
        
        private var visualConfig: VisualLookConfig
        private let closeClosure: () -> Void
        private let cornerRadius = 10.0
        private let borderWidth = 10.0
        
        @ObservedObject private var viewModel: OwnID.FlowsSDK.LoginView.ViewModel
        @State private var email = ""
        
        private let resultPublisher = PassthroughSubject<Void, Never>()
        
        public init(viewModel: OwnID.FlowsSDK.LoginView.ViewModel,
                    visualConfig: VisualLookConfig,
                    closeClosure: @escaping () -> Void) {
            self.viewModel = viewModel
            self.visualConfig = visualConfig
            self.closeClosure = closeClosure
            self.visualConfig.authButtonConfig.backgroundColor = OwnID.Colors.instantConnectViewAuthButtonColor
            
            viewModel.updateEmailPublisher(emailPublisher.eraseToAnyPublisher())
            viewModel.subscribe(to: eventPublisher)
        }
        
        var eventPublisher: OwnID.UISDK.EventPubliser {
            resultPublisher
                .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        
        public var body: some View {
            if #available(iOS 15.0, *) {
                viewContent()
                    .onChange(of: email) { newValue in emailPublisher.send(newValue) }
            } else {
                viewContent()
            }
        }
        
        @ViewBuilder
        private func viewContent() -> some View {
            VStack {
                HStack {
                    Text("Sign In")
                        .font(.system(size: 20))
                        .bold()
                    Spacer()
                    Button {
                        closeClosure()
                    } label: {
                        Image("closeImage", bundle: .resourceBundle)
                    }
                }
                VStack {
                    Text("Enter your email")
                        .font(.system(size: 18))
                    TextField("", text: $email)
                        .font(.system(size: 17))
                        .keyboardType(.emailAddress)
                        .padding(11)
                        .background(Rectangle().fill(.white))
                        .cornerRadius(cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(OwnID.Colors.instantConnectViewEmailFiendBorderColor, lineWidth: 1.5)
                        )
                        .padding(.bottom, 6)
                    AuthButton(visualConfig: visualConfig,
                               actionHandler: { resultPublisher.send(()) },
                               isLoading: viewModel.state.isLoadingBinding,
                               buttonState: viewModel.state.buttonStateBinding)
                }
            }
            .padding()
        }
    }
}
