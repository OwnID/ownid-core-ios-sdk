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
        
        @available(iOS 15.0, *)
        public static var popupViewBackgroundColor: Color {
            Color("\(OwnID.UISDK.PopupView.self)BackgroundColor", bundle: .resourceBundle)
        }
        
        @available(iOS 15.0, *)
        public static var instantConnectViewEmailFiendBorderColor: Color {
            Color("\(OwnID.UISDK.InstantConnectView.self)EmailFiendBorderColor", bundle: .resourceBundle)
        }
        
        @available(iOS 15.0, *)
        public static var instantConnectViewAuthButtonColor: Color {
            Color("\(OwnID.UISDK.InstantConnectView.self)AuthButtonColor", bundle: .resourceBundle)
        }
        
        public static var otpContentMessageColor: Color {
            Color("\(OwnID.UISDK.OneTimePasswordView.self)contentMessage", bundle: .resourceBundle)
        }
        
        public static var otpContentErrorColor: Color {
            Color("\(OwnID.UISDK.OneTimePasswordView.self)ErrorColor", bundle: .resourceBundle)
        }
        
        public static var otpTileBackgroundColor: Color {
            Color("\(OwnID.UISDK.OneTimePasswordView.self)TileBackgroundColor", bundle: .resourceBundle)
        }
        
        public static var otpTileBorderColor: Color {
            Color("\(OwnID.UISDK.OneTimePasswordView.self)TileBorderColor", bundle: .resourceBundle)
        }
        
        public static var otpTileSelectedBorderColor: Color {
            Color("\(OwnID.UISDK.OneTimePasswordView.self)TileSelectedBorderColor", bundle: .resourceBundle)
        }
    }
}
