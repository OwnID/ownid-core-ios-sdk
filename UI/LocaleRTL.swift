import Foundation

extension Locale {
    var isRTL: Bool {
        guard let language = language.languageCode else { return false }
        let direction = Locale.Language(identifier: language.identifier).characterDirection
        switch direction {
        case .leftToRight:
            return false
        default:
            return true
        }
    }
}
