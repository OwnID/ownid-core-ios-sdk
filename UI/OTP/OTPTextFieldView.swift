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
        @FocusState private var focusedField: Int?
        
        public var body: some View {
            HStack(spacing: Constants.spaceBetweenBoxes) {
                ForEach(0..<viewModel.codeLength, id: \.self) { index in
                    ZStack {
                        Rectangle()
                            .foregroundColor(OwnID.Colors.otpTileBackgroundColor)
                            .border(tileBorderColor(for: index))
                            .cornerRadius(cornerRadiusValue)
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadiusValue)
                                    .stroke(tileBorderColor(for: index), lineWidth: Constants.textFieldBorderWidth)
                            )
                        
                        TextField("", text: $viewModel.codes[index])
                            .font(.system(size: Constants.fontSize))
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: index)
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
        
        private func tileBorderColor(for index: Int) -> Color {
            focusedField == index ? OwnID.Colors.otpTileSelectedBorderColor : OwnID.Colors.otpTileBorderColor
        }
    }
}
