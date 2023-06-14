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
            try? createRootDirectoryIfNeeded()
            try? copyEnglishModuleTranslationsToDocuments()
            translationBundle = Bundle(path: moduleEnglishBundlePath)
        }
        
        private let bundleFileExtension = "bundle"
        
        func save(languageKey: LanguageKey, language: Language, tableName: String = "Localizable") throws {
            try cleanRootContents()
            try write(languageKey: languageKey, language: language, tableName: tableName)
            
            translationBundle = Bundle(path: languageBundlePath(language: languageKey))
        }
    }
}

private extension OwnID.CoreSDK.TranslationsSDK.RuntimeLocalizableSaver {
    var moduleEnglishBundlePath: String {
        languageBundlePath(language: "ModuleEN")
    }
    
    func createLprojDirectoryIfNeeded(_ lprojFilePath: String) throws {
        if fileManager.fileExists(atPath: lprojFilePath) == false {
            do {
                try fileManager.createDirectory(atPath: lprojFilePath, withIntermediateDirectories: true)
            } catch let error {
                throw OwnID.CoreSDK.CoreErrorLogWrapper.coreLog(entry: .errorEntry(Self.self), error: .localizationManager(underlying: error))
            }
        }
    }
    
    func copyTranslatedFilesIfNeeded(_ lprojFilePath: String, _ moduleTranslations: String) throws {
        let localizableFilePath = lprojFilePath + "/Localizable.strings"
        if fileManager.fileExists(atPath: localizableFilePath) == false {
            do {
                try fileManager.copyItem(atPath: moduleTranslations, toPath: localizableFilePath)
            } catch let error {
                throw OwnID.CoreSDK.CoreErrorLogWrapper.coreLog(entry: .errorEntry(Self.self), error: .localizationManager(underlying: error))
            }
        }
    }
    
    func copyEnglishModuleTranslationsToDocuments() throws {
        let lprojFilePath = moduleEnglishBundlePath + "/en.lproj"
        guard let moduleTranslations = Bundle.resourceBundle.path(forResource: "Localizable", ofType: "strings") else { return }
        try createLprojDirectoryIfNeeded(lprojFilePath)

        try copyTranslatedFilesIfNeeded(lprojFilePath, moduleTranslations)
    }
    
    func languageBundlePath(language: String) -> String {
        rootFolderPath + "/" + language + "Translations." + bundleFileExtension
    }
    
    func cleanRootContents() throws {
        guard fileManager.fileExists(atPath: rootFolderPath) else { return }
        guard let filePaths = try? fileManager.contentsOfDirectory(atPath: rootFolderPath) else { return }
        for filePath in filePaths where filePath.contains(".\(bundleFileExtension)") {
            let fullFilePath = rootFolderPath + "/" + filePath
            do {
                try fileManager.removeItem(atPath: fullFilePath)
            } catch let error {
                throw OwnID.CoreSDK.CoreErrorLogWrapper.coreLog(entry: .errorEntry(Self.self), error: .localizationManager(underlying: error))
            }
        }
    }
    
    func createRootDirectoryIfNeeded() throws {
        if fileManager.fileExists(atPath: rootFolderPath) == false {
            do {
                try fileManager.createDirectory(atPath: rootFolderPath, withIntermediateDirectories: true)
            } catch let error {
                throw OwnID.CoreSDK.CoreErrorLogWrapper.coreLog(entry: .errorEntry(Self.self), error: .localizationManager(underlying: error))
            }
        }
    }
    
    func write(languageKey: LanguageKey, language: Language, tableName: String) throws {
        let languageTablePath = languageBundlePath(language: languageKey) + "/\(languageKey).lproj"
        if fileManager.fileExists(atPath: languageTablePath) == false {
            do {
                try fileManager.createDirectory(atPath: languageTablePath, withIntermediateDirectories: true)
            } catch let error {
                throw OwnID.CoreSDK.CoreErrorLogWrapper.coreLog(entry: .errorEntry(Self.self), error: .localizationManager(underlying: error))
            }
        }
        
        let fileContentsString = language.reduce("", { $0 + "\"\($1.key)\" = \"\($1.value)\";\n" })
        
        let fileData = fileContentsString.data(using: .utf32)
        let filePath = languageTablePath + "/\(tableName).strings"
        fileManager.createFile(atPath: filePath, contents: fileData)
        let message = "Wrote bundle strings to languageKey \(languageKey)"
        OwnID.CoreSDK.logger.log(.entry(level: .debug, message: message, OwnID.CoreSDK.TranslationsSDK.RuntimeLocalizableSaver.self))
    }
}
