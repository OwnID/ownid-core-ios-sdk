import SwiftUI

extension Text {
    init(localizedKey: OwnID.CoreSDK.TranslationsSDK.TranslationKey) {
        self.init(.init(localizedKey.rawValue), bundle: OwnID.CoreSDK.shared.translationsModule.localizationBundle)
    }
}
