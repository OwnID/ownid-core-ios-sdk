import Foundation

extension OwnID.CoreSDK.TranslationsSDK {
    final class RuntimeLocalizableSaver {
        
        typealias LanguageKey = String
        typealias Language = Dictionary<String, String>
        
        var translationBundle: Bundle?
        
        private static let rootFolderName = "\(OwnID.CoreSDK.TranslationsSDK.self)"
        private let fileManager = FileManager.default
        
        private lazy var rootFolderPath: String = {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let bundlePath = documentsPath + "/" + RuntimeLocalizableSaver.rootFolderName
            return bundlePath
        }()
        
        init() {
            createRootDirectoryIfNeeded()
            copyEnglishModuleTranslationsToDocuments()
            translationBundle = Bundle(path: moduleEnglishBundlePath)
        }
        
        private let bundleFileExtension = "bundle"
        
        func save(languageKey: LanguageKey, language: Language, tableName: String = "Localizable") {
            cleanRootContents()
            write(languageKey: languageKey, language: language, tableName: tableName)
            
            translationBundle = Bundle(path: languageBundlePath(language: languageKey))
        }
    }
}

private extension OwnID.CoreSDK.TranslationsSDK.RuntimeLocalizableSaver {
    var moduleEnglishBundlePath: String {
        languageBundlePath(language: "ModuleEN")
    }
    
    func createLprojDirectoryIfNeeded(_ lprojFilePath: String) {
        if fileManager.fileExists(atPath: lprojFilePath) == false {
            do {
                try fileManager.createDirectory(atPath: lprojFilePath, withIntermediateDirectories: true)
            } catch let error {
                OwnID.CoreSDK.logger.logCore(.errorEntry(message: error.localizedDescription, OwnID.CoreSDK.TranslationsSDK.RuntimeLocalizableSaver.self))
            }
        }
    }
    
    func copyTranslatedFilesIfNeeded(_ lprojFilePath: String, _ moduleTranslations: String) {
        let localizableFilePath = lprojFilePath + "/Localizable.strings"
        if fileManager.fileExists(atPath: localizableFilePath) == false {
            do {
                try fileManager.copyItem(atPath: moduleTranslations, toPath: localizableFilePath)
            } catch let error {
                OwnID.CoreSDK.logger.logCore(.errorEntry(message: error.localizedDescription, OwnID.CoreSDK.TranslationsSDK.RuntimeLocalizableSaver.self))
            }
        }
    }
    
    func copyEnglishModuleTranslationsToDocuments() {
//        let lprojFilePath = moduleEnglishBundlePath + "/en.lproj"
//        guard let moduleTranslations = Bundle.module.path(forResource: "Localizable", ofType: "strings") else { return }
//        createLprojDirectoryIfNeeded(lprojFilePath)
//
//        copyTranslatedFilesIfNeeded(lprojFilePath, moduleTranslations)
    }
    
    func languageBundlePath(language: String) -> String {
        rootFolderPath + "/" + language + "Translations." + bundleFileExtension
    }
    
    func cleanRootContents() {
        guard fileManager.fileExists(atPath: rootFolderPath) else { return }
        guard let filePaths = try? fileManager.contentsOfDirectory(atPath: rootFolderPath) else { return }
        for filePath in filePaths where filePath.contains(".\(bundleFileExtension)") {
            let fullFilePath = rootFolderPath + "/" + filePath
            do {
                try fileManager.removeItem(atPath: fullFilePath)
            } catch let error {
                OwnID.CoreSDK.logger.logCore(.errorEntry(message: error.localizedDescription, OwnID.CoreSDK.TranslationsSDK.RuntimeLocalizableSaver.self))
            }
        }
    }
    
    func createRootDirectoryIfNeeded() {
        if fileManager.fileExists(atPath: rootFolderPath) == false {
            do {
                try fileManager.createDirectory(atPath: rootFolderPath, withIntermediateDirectories: true)
            } catch let error {
                OwnID.CoreSDK.logger.logCore(.errorEntry(message: error.localizedDescription, OwnID.CoreSDK.TranslationsSDK.RuntimeLocalizableSaver.self))
            }
        }
    }
    
    func write(languageKey: LanguageKey, language: Language, tableName: String) {
        let languageTablePath = languageBundlePath(language: languageKey) + "/\(languageKey).lproj"
        if fileManager.fileExists(atPath: languageTablePath) == false {
            do {
                try fileManager.createDirectory(atPath: languageTablePath, withIntermediateDirectories: true)
            } catch let error {
                OwnID.CoreSDK.logger.logCore(.errorEntry(message: error.localizedDescription, OwnID.CoreSDK.TranslationsSDK.RuntimeLocalizableSaver.self))
            }
        }
        
        let fileContentsString = language.reduce("", { $0 + "\"\($1.key)\" = \"\($1.value)\";\n" })
        
        let fileData = fileContentsString.data(using: .utf32)
        let filePath = languageTablePath + "/\(tableName).strings"
        fileManager.createFile(atPath: filePath, contents: fileData)
        let message = "Wrote bundle strings to languageKey \(languageKey)"
        OwnID.CoreSDK.logger.logCore(.entry(message: message, OwnID.CoreSDK.TranslationsSDK.RuntimeLocalizableSaver.self))
    }
}
