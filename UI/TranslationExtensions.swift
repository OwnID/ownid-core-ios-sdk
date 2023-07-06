import SwiftUI

extension Text {
    init(localizedKey: OwnID.CoreSDK.TranslationsSDK.TranslationKey) {
        if let string = localizedKey.value {
            self.init(string)
        } else {
            self.init(.init(localizedKey.defaultValue), bundle: Bundle.resourceBundle)
        }
    }
}
