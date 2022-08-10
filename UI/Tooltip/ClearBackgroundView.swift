import SwiftUI
import OwnIDCoreSDK

extension OwnID.UISDK {
    struct ClearBackgroundView: UIViewRepresentable {
        func makeUIView(context: Context) -> some UIView {
            let view = UIView()
            DispatchQueue.main.async {
                view.superview?.superview?.backgroundColor = .clear
            }
            return view
        }
        func updateUIView(_ uiView: UIViewType, context: Context) { }
    }
    
    struct ClearBackgroundViewModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .background(ClearBackgroundView())
        }
    }
}

extension View {
    func clearPresentedModalBackground() -> some View {
        modifier(OwnID.UISDK.ClearBackgroundViewModifier())
    }
}
