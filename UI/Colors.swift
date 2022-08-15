import Foundation
import OwnIDCoreSDK
import SwiftUI

public extension OwnID {
    enum Colors {
        public static var blue: Color {
            Color("blue", bundle: .module)
        }
        
        public static var darkBlue: Color {
            Color("darkBlue", bundle: .module)
        }
        
        public static var linkDarkBlue: Color {
            Color("linkDarkBlue", bundle: .module)
        }
        
        public static var textGrey: Color {
            Color("textGrey", bundle: .module)
        }
        
        public static var biometricsButtonBorder: Color {
            Color("biometricsButtonBorder", bundle: .module)
        }
        
        public static var biometricsButtonBackground: Color {
            Color("biometricsButtonBackground", bundle: .module)
        }
        
        public static var biometricsButtonImageColor: Color {
            Color("biometricsButtonImageColor", bundle: .module)
        }
        
        public static var defaultBlackColor: Color {
            Color("defaultBlack", bundle: .module)
        }
    }
}
