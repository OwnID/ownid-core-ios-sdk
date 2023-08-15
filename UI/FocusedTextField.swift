
import SwiftUI

@available(iOS 15.0, *)
private struct FocusedTextField: ViewModifier {
    
    @FocusState private var focused: Bool
    @Binding private var externalFocused: Bool
    
    init(externalFocused: Binding<Bool>) {
        self._externalFocused = externalFocused
        self.focused = externalFocused.wrappedValue
    }
    
    func body(content: Content) -> some View {
        content
            .focused($focused)
            .onChange(of: externalFocused) { newValue in
                focused = newValue
            }
            .onAppear {
                if #available(iOS 16.0, *) {
                    focused = externalFocused
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        focused = externalFocused
                    }
                }
            }
    }
}

@available(iOS 15.0, *)
private struct MultipleFocusedTextField<Value: Hashable>: ViewModifier {
    @FocusState private var focused: Bool
    @Binding private var externalFocused: Value
    private var equalsValue: Value
    
    init(externalFocused: Binding<Value>, equalsValue: Value) {
        self._externalFocused = externalFocused
        self.equalsValue = equalsValue
        self.focused = externalFocused.wrappedValue == equalsValue
    }
    
    func body(content: Content) -> some View {
        content
            .focused($focused)
            .onChange(of: externalFocused) { newValue in
                print("onChange \(externalFocused) --- \(equalsValue)")
                focused = newValue == equalsValue
            }
            .onAppear {
                print("\(externalFocused) --- \(equalsValue)")
                if #available(iOS 16.0, *) {
                    focused = externalFocused == equalsValue
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        focused = externalFocused == equalsValue
                    }
                }
            }
    }
}

extension View {
    @ViewBuilder
    func focused(_ value: Binding<Bool>) -> some View {
        if #available(iOS 15.0, *) {
            self.modifier(FocusedTextField(externalFocused: value))
        } else {
            self
        }
    }
    
    func focused<Value>(_ value: Binding<Value>, equals: Value) -> some View where Value: Hashable {
        if #available(iOS 15.0, *) {
            return self.modifier(MultipleFocusedTextField(externalFocused: value, equalsValue: equals))
        } else {
            return self
        }
    }
}
