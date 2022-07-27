import XCTest
import Combine
@testable import OwnIDCoreSDK

/// Tests show that for fixed input there is fixed output
final class RuntimeLocalizableSaverTests: XCTestCase {
    override class func setUp() {
        OwnID.CoreSDK.shared.configureForTests()
    }
    
    func testSavingToLocalizableStringsBundle() {
        //Arrange (given)
        let userDefinedLanguage = "zh-Hant-HK"
        let translationValue = "translated_text_in_localized_file"
        let language = ["or": translationValue]
        let saver = OwnID.CoreSDK.TranslationsSDK.RuntimeLocalizableSaver()
        
        //Act (when)
        saver.save(languageKey: userDefinedLanguage, language: language)
        
        //Assert (then)
        let path = saver.translationBundle?.bundlePath
        guard let path = path, path.contains(userDefinedLanguage) else { XCTFail(); return }
        
        guard let localizableFilePath = saver.translationBundle?.path(forResource: "Localizable", ofType: "strings") else { XCTFail(); return }
        guard let fileContents = try? String(contentsOfFile: localizableFilePath, encoding: .utf32) else { XCTFail(); return }
        guard fileContents.contains(translationValue) else { XCTFail(); return }
    }
}
