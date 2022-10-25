import Foundation
import SwiftUI

public extension OwnID {
    enum Colors {
        public static var blue: Color {
            Color("blue", bundle: .resourceBundle)
        }
        
        public static var darkBlue: Color {
            Color("darkBlue", bundle: .resourceBundle)
        }
        
        public static var linkDarkBlue: Color {
            Color("linkDarkBlue", bundle: .resourceBundle)
        }
        
        public static var textGrey: Color {
            Color("textGrey", bundle: .resourceBundle)
        }
        
        public static var biometricsButtonBorder: Color {
            Color("biometricsButtonBorder", bundle: .resourceBundle)
        }
        
        public static var biometricsButtonBackground: Color {
            Color("biometricsButtonBackground", bundle: .resourceBundle)
        }
        
        public static var biometricsButtonImageColor: Color {
            Color("biometricsButtonImageColor", bundle: .resourceBundle)
        }
        
        public static var defaultBlackColor: Color {
            Color("defaultBlack", bundle: .resourceBundle)
        }
    }
}
