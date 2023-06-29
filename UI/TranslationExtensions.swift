import SwiftUI

extension Text {
    init(localizedKey: OwnID.CoreSDK.TranslationsSDK.TranslationKey) {
        if let string = OwnID.CoreSDK.shared.translationsModule.localizedString(for: localizedKey.value) {
            self.init(string)
        } else {
            self.init(.init(localizedKey.value), bundle: Bundle.resourceBundle)
        }
    }
}
