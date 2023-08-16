
import SwiftUI

struct FocusedTextField<Value: Hashable>: UIViewRepresentable {

    @Binding var focusedField: Value?
    @Binding var text: String
    
    let equals: Value

    public var configuration = { (view: UITextField) in }

    public init(text: Binding<String>, focusedField: Binding<Value?>, equals: Value, configuration: @escaping (UITextField) -> () = { _ in }) {
        self.configuration = configuration
        self._text = text
        self._focusedField = focusedField
        self.equals = equals
    }

    public func makeUIView(context: Context) -> UITextField {
        let view = UITextField()
        view.addTarget(context.coordinator, action: #selector(Coordinator.textViewDidChange), for: .editingChanged)
        view.delegate = context.coordinator
        return view
    }

    public func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        configuration(uiView)
        switch focusedField == equals {
        case true: uiView.becomeFirstResponder()
        case false: uiView.resignFirstResponder()
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator($text, focusedField: $focusedField, equals: equals)
    }

    public class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>
        var focusedField: Binding<Value?>
        
        let equals: Value

        init(_ text: Binding<String>, focusedField: Binding<Value?>, equals: Value) {
            self.text = text
            self.focusedField = focusedField
            self.equals = equals
        }

        @objc public func textViewDidChange(_ textField: UITextField) {
            self.text.wrappedValue = textField.text ?? ""
        }

        public func textFieldDidBeginEditing(_ textField: UITextField) {
            self.focusedField.wrappedValue = equals
        }

        public func textFieldDidEndEditing(_ textField: UITextField) {
            self.focusedField.wrappedValue = nil
        }
    }
}
