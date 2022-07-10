import XCTest
import Combine
@testable import OwnIDCoreSDK

/// Tests show that for fixed input there is fixed output
final class LanguageMapperTests: XCTestCase {
    func testLanguageMappingZH() {
        //Arrange (given)
        let userDefinedLanguages = ["zh-Hant-HK"]
        let serverLanguage = "zh-TW"
        
        //Act (when)
        let output = OwnID.CoreSDK.TranslationsSDK.LanguageMapper().matchSystemLanguage(to: [serverLanguage], userDefinedLanguages: userDefinedLanguages)
        
        //Assert (then)
        XCTAssertEqual(serverLanguage, output.serverLanguage)
    }
    
    func testLanguageMappingNB() {
        //Arrange (given)
        let userDefinedLanguages = ["nb"]
        let serverLanguage = "no"
        
        //Act (when)
        let output = OwnID.CoreSDK.TranslationsSDK.LanguageMapper().matchSystemLanguage(to: [serverLanguage], userDefinedLanguages: userDefinedLanguages)
        
        //Assert (then)
        XCTAssertEqual(serverLanguage, output.serverLanguage)
    }
}
