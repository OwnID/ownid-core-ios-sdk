import SwiftUI
import Combine

extension OwnID.UISDK {
    @available(iOS 15.0, *)
    public struct OTPTextFieldView: View {
        private enum Constants {
            static let boxSideSize: CGFloat = 50.0
            static let spaceBetweenBoxes: CGFloat = 8.0
            static let textFieldBorderWidth = 1.0
            static let fontSize = 20.0
            static let textFieldPadding = 12.0
        }
        
        @ObservedObject var viewModel: ViewModel
        @FocusState private var focusedField: ViewModel.FieldType?
        
        public var body: some View {
            HStack(spacing: Constants.spaceBetweenBoxes) {
                ForEach(viewModel.codeLength.fields, id: \.self) { field in
                    ZStack {
                        Rectangle()
                            .foregroundColor(OwnID.Colors.otpTileBackgroundColor)
                            .border(tileBorderColor(for: field))
                            .cornerRadius(cornerRadiusValue)
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadiusValue)
                                    .stroke(tileBorderColor(for: field), lineWidth: Constants.textFieldBorderWidth)
                            )
                        
                        TextField("", text: binding(for: field))
                            .font(.system(size: Constants.fontSize))
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: field)
                            .padding(Constants.textFieldPadding)
                            .disabled(viewModel.disableTextFields)
                    }
                    .frame(width: Constants.boxSideSize, height: Constants.boxSideSize)
                }
            }
            .onChange(of: viewModel.currentFocusedField, perform: { newValue in
                focusedField = newValue
            })
            .onChange(of: viewModel.code1, perform: { newValue in
                viewModel.processTextChange(for: .one, binding: $viewModel.code1)
            })
            .onChange(of: viewModel.code2, perform: { newValue in
                viewModel.processTextChange(for: .two, binding: $viewModel.code2)
            })
            .onChange(of: viewModel.code3, perform: { newValue in
                viewModel.processTextChange(for: .three, binding: $viewModel.code3)
            })
            .onChange(of: viewModel.code4, perform: { newValue in
                viewModel.processTextChange(for: .four, binding: $viewModel.code4)
            })
            .onChange(of: viewModel.code5, perform: { newValue in
                viewModel.processTextChange(for: .five, binding: $viewModel.code5)
            })
            .onChange(of: viewModel.code6, perform: { newValue in
                viewModel.processTextChange(for: .six, binding: $viewModel.code6)
            })
            .onAppear() {
                focusedField = .one
            }
        }
        
        private func tileBorderColor(for field: ViewModel.FieldType) -> Color {
            focusedField == field ? OwnID.Colors.otpTileSelectedBorderColor : OwnID.Colors.otpTileBorderColor
        }
        
        private func binding(for field: ViewModel.FieldType) -> Binding<String> {
            switch field {
            case .one:
                return $viewModel.code1
            case .two:
                return $viewModel.code2
            case .three:
                return $viewModel.code3
            case .four:
                return $viewModel.code4
            case .five:
                return $viewModel.code5
            case .six:
                return $viewModel.code6
            }
        }
    }
}
