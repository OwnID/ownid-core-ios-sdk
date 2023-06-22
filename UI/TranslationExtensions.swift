import SwiftUI

extension Text {
    init(localizedKey: OwnID.CoreSDK.TranslationsSDK.TranslationKey) {
        self.init(.init(localizedKey.value), bundle: OwnID.CoreSDK.shared.translationsModule.localizationBundle(for: localizedKey.value))
    }
}
