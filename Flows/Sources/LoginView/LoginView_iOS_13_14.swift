import UIKit

@available(iOS, introduced: 13, obsoleted: 14, message: "Use class for iOS 15")
public extension OwnID.FlowsSDK {
    final class LoginView_iOS_13_14: UIView {
        private var usersEmail: String
        public var visualConfig = OwnID.UISDK.VisualLookConfig()
        
        public var viewModel: FlowsLoginViewModel
        
        private let redBackgroundButton = UIButton()
        
        public init(viewModel: FlowsLoginViewModel,
                    usersEmail: String) {
            self.viewModel = viewModel
            self.usersEmail = usersEmail
            super.init(frame: .zero)
            self.viewModel.getEmail = { usersEmail }
            redBackgroundButton.setTitle("OwnID", for: .normal)
            redBackgroundButton.setTitle("OwnID Pressed", for: .highlighted)
            redBackgroundButton.addTarget(self, action: #selector(pressedAction), for: .touchUpInside)
            redBackgroundButton.backgroundColor = .red
            
            addSubview(redBackgroundButton)
            translatesAutoresizingMaskIntoConstraints = false
            
            redBackgroundButton.translatesAutoresizingMaskIntoConstraints = false
            redBackgroundButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            redBackgroundButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            redBackgroundButton.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
            redBackgroundButton.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        @objc
        private func pressedAction() {
          print("you clicked on button")
        }
    }
}
