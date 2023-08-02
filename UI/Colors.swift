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
        
        public static var spinnerColor: Color {
            Color("spinnerStrokeColor", bundle: .resourceBundle)
        }
        
        public static var spinnerBackgroundColor: Color {
            Color("spinnerBackgroundStrokeColor", bundle: .resourceBundle)
        }
        
        public static var authButtonSpinnerColor: Color {
            Color("authButtonSpinnerStrokeColor", bundle: .resourceBundle)
        }
        
        public static var authButtonSpinnerBackgroundColor: Color {
            Color("authButtonSpinnerBackgroundStrokeColor", bundle: .resourceBundle)
        }
        
        @available(iOS 15.0, *)
        public static var idCollectViewLoginFieldBorderColor: Color {
            Color("\(OwnID.UISDK.IdCollect.IdCollectView.self)LoginFieldBorderColor", bundle: .resourceBundle)
        }
        
        @available(iOS 15.0, *)
        public static var idCollectViewLoginFieldBackgroundColor: Color {
            Color("\(OwnID.UISDK.IdCollect.IdCollectView.self)LoginFieldBackgroundColor", bundle: .resourceBundle)
        }
        
        public static var popupContentMessageColor: Color {
            Color("PopupContentMessage", bundle: .resourceBundle)
        }
        
        public static var errorColor: Color {
            Color("errorColor", bundle: .resourceBundle)
        }
        
        public static var otpTitleBackgroundColor: Color {
            Color("\(OwnID.UISDK.OneTimePassword.self)TitleBackgroundColor", bundle: .resourceBundle)
        }
        
        public static var otpTitleBorderColor: Color {
            Color("\(OwnID.UISDK.OneTimePassword.self)TitleBorderColor", bundle: .resourceBundle)
        }
        
        public static var otpTitleSelectedBorderColor: Color {
            Color("\(OwnID.UISDK.OneTimePassword.self)TitleSelectedBorderColor", bundle: .resourceBundle)
        }
        
        public static var otpDidNotGetEmail: Color {
            Color("\(OwnID.UISDK.OneTimePassword.self)didNotGetEmail", bundle: .resourceBundle)
        }
    }
}
