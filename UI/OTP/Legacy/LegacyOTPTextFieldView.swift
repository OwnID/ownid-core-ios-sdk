import SwiftUI
import Combine

extension OwnID.UISDK {
    public struct LegacyOTPTextFieldView: View {
        private enum Constants {
            static let boxSideSize: CGFloat = 50.0
            static let spaceBetweenBoxes: CGFloat = 8.0
            static let textFieldBorderWidth = 1.0
            static let fontSize = 20.0
            static let textFieldPadding = 8.0
        }
        
        @ObservedObject var viewModel: OneTimePassword.ViewModel
        @State private var focusedField: Int?
        
        public var body: some View {
            HStack(spacing: Constants.spaceBetweenBoxes) {
                ForEach(0..<viewModel.codeLength, id: \.self) { index in
                    ZStack {
                        Rectangle()
                            .foregroundColor(OwnID.Colors.otpTitleBackgroundColor)
                            .border(titleBorderColor(for: index))
                            .cornerRadius(cornerRadiusValue)
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadiusValue)
                                    .stroke(titleBorderColor(for: index), lineWidth: Constants.textFieldBorderWidth)
                            )
                        FocusedTextField(text: $viewModel.codes[index], focusedField: $focusedField, equals: index, configuration: { textField in
                            textField.keyboardType = .numberPad
                            textField.textAlignment = .center
                            textField.tag = index
                            textField.textColor = UIColor(OwnID.Colors.blue)
                            textField.font = UIFont.systemFont(ofSize: Constants.fontSize, weight: .medium)
                        })
                        .onTapGesture(perform: {
                            focusedField = index
                        })
                            .disabled(viewModel.isDisabled)
                            .padding(Constants.textFieldPadding)
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: Constants.boxSideSize, maxHeight: Constants.boxSideSize)
                }
            }
            .onChange(of: viewModel.currentFocusedFieldIndex, perform: { newValue in
                focusedField = newValue
            })
            .onChange(of: viewModel.codes, perform: { newValue in
                guard let index = focusedField else { return }
                viewModel.processTextChange(for: index, binding: $viewModel.codes[index])
            })
            .onAppear() {
                focusedField = 0
            }
        }
        
        private func titleBorderColor(for index: Int) -> Color {
            focusedField == index ? OwnID.Colors.otpTitleSelectedBorderColor : OwnID.Colors.otpTitleBorderColor
        }
    }
}
