import SwiftUI
import Combine

extension OwnID.UISDK.OneTimePasswordCodeLength {
    var fields: [OwnID.UISDK.OTPViewModel.FieldType] {
        switch self {
        case .four:
            return [.one, .two, .three, .four]
            
        case .six:
            return [.one, .two, .three, .four, .five, .six]
        }
    }
}

extension OwnID.UISDK.OTPViewModel {
    enum FieldType: Identifiable, Hashable {
        var id: Self {
            return self
        }
        
        var rawValue: Int {
            switch self {
            case .one:
                return 1
                
            case .two:
                return 2
                
            case .three:
                return 3
                
            case .four:
                return 4
                
            case .five:
                return 5
                
            case .six:
                return 6
            }
        }
        
        case one
        case two
        case three
        case four
        case five
        case six
    }
}

extension OwnID.UISDK {
    final class OTPViewModel: ObservableObject {
        init(codeLength: OwnID.UISDK.OneTimePasswordCodeLength,
             store: Store<OwnID.UISDK.OneTimePasswordView.ViewState, OwnID.UISDK.OneTimePasswordView.Action>) {
            self.codeLength = codeLength
            self.store = store
            storage = Array(repeating: "", count: codeLength.rawValue + 1)
        }
        
        let codeLength: OneTimePasswordCodeLength
        
        let store: Store<OwnID.UISDK.OneTimePasswordView.ViewState, OwnID.UISDK.OneTimePasswordView.Action>
        private var storage: [String]
        
        func onUpdateOf(field: FieldType, value: String) {
            storage[field.rawValue] = value
        }
        
        func combineCode() -> String {
            let code = storage.reduce("", +)
            return code
        }
    }
}

extension OwnID.UISDK {
    @available(iOS 15.0, *)
    public struct OTPTextFieldView: View {
        @ObservedObject var viewModel: OTPViewModel
        @FocusState private var focusedField: OwnID.UISDK.OTPViewModel.FieldType?
        private let boxSideSize: CGFloat = 50
        private let spaceBetweenBoxes: CGFloat = 8
        private let cornerRadius = 6.0
        private let characterLimit = 1
        
        @State var code1 = ""
        @State var code2 = ""
        @State var code3 = ""
        @State var code4 = ""
        @State var code5 = ""
        @State var code6 = ""
        
        public var body: some View {
            HStack(spacing: spaceBetweenBoxes) {
                ForEach(viewModel.codeLength.fields, id: \.self) { field in
                    ZStack {
                        Rectangle()
                            .foregroundColor(OwnID.Colors.otpTileBackgroundColor)
                            .border(tileBorderColor(for: field))
                            .cornerRadius(cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(tileBorderColor(for: field), lineWidth: 1)
                            )
                        
                        TextField("", text: binding(for: field))
                            .font(Font.system(size: 20))
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: field)
                            .padding(12)
                    }
                    .frame(width: boxSideSize, height: boxSideSize)
                }
            }
//            .onReceive(Just(code6)) { _ in  }
//            .onReceive(Just(code4)) { _ in  }
            .onChange(of: code1, perform: { newValue in
                if newValue.count > characterLimit {
                    code1 = String(newValue.prefix(characterLimit))
                }
                processTextChange(for: .one, value: code1)
            })
            .onChange(of: code2, perform: { newValue in
                if newValue.count > characterLimit {
                    code2 = String(newValue.prefix(characterLimit))
                }
                processTextChange(for: .two, value: code2)
            })
            .onChange(of: code3, perform: { newValue in
                if newValue.count > characterLimit {
                    code3 = String(newValue.prefix(characterLimit))
                }
                processTextChange(for: .three, value: code3)
            })
            .onChange(of: code4, perform: { newValue in
                if newValue.count > characterLimit {
                    code4 = String(newValue.prefix(characterLimit))
                }
                processTextChange(for: .four, value: code4)
            })
            .onChange(of: code5, perform: { newValue in
                if newValue.count > characterLimit {
                    code5 = String(newValue.prefix(characterLimit))
                }
                processTextChange(for: .five, value: code5)
            })
            .onChange(of: code6, perform: { newValue in
                if newValue.count > characterLimit {
                    code6 = String(newValue.prefix(characterLimit))
                }
                processTextChange(for: .six, value: code6)
            })
            .onAppear() {
                focusedField = .one
            }
        }
        
        func processTextChange(for field: OwnID.UISDK.OTPViewModel.FieldType, value: String) {
            viewModel.onUpdateOf(field: field, value: value)
            switch field {
            case .one:
                if !code1.isEmpty {
                    focusedField = .two
                }
                
            case .two:
                if code2.isEmpty {
                    focusedField = .one
                } else {
                    focusedField = .three
                }
                
            case .three:
                if code3.isEmpty {
                    focusedField = .two
                } else {
                    focusedField = .four
                }
                
            case .four:
                if code4.isEmpty {
                    focusedField = .three
                } else {
                    if viewModel.codeLength == .four {
                        submitCode()
                    } else {
                        focusedField = .five
                    }
                }
                
            case .five:
                if code5.isEmpty {
                    focusedField = .four
                } else {
                    focusedField = .six
                }
                
            case .six:
                if code6.isEmpty {
                    focusedField = .five
                } else {
                    submitCode()
                }
            }
        }
        
        func submitCode() {
            viewModel.store.send(.codeEntered(viewModel.combineCode()))
        }
        
        func tileBorderColor(for field: OwnID.UISDK.OTPViewModel.FieldType) -> Color {
            focusedField == field ? OwnID.Colors.otpTileSelectedBorderColor : OwnID.Colors.otpTileBorderColor
        }
        
        func binding(for field: OwnID.UISDK.OTPViewModel.FieldType) -> Binding<String> {
            switch field {
            case .one:
                return $code1
            case .two:
                return $code2
            case .three:
                return $code3
            case .four:
                return $code4
            case .five:
                return $code5
            case .six:
                return $code6
            }
        }
    }
}
