import Foundation

extension OwnID.CoreSDK.TranslationsSDK {
    final class RuntimeLocalizableSaver {
        private enum Constants {
            static let bundleFileExtension = "bundle"
            static let currentLanguageKey = "currentLanguageKey"
            static let defaultFileName = "Localizable"
            static let localizableType = "strings"
            static let enBundleName = "ModuleEN"
        }
        
        typealias LanguageKey = String
        typealias Language = Dictionary<String, String>

        private static let rootFolderName = "\(OwnID.CoreSDK.TranslationsSDK.self)"
        private let fileManager = FileManager.default
        private var currentLanguageKey: LanguageKey? {
            get {
                UserDefaults.standard.string(forKey: Constants.currentLanguageKey)
            } set {
                UserDefaults.standard.set(newValue, forKey: Constants.currentLanguageKey)
            }
        }
        
        private lazy var rootFolderPath: String = {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let bundlePath = documentsPath + "/" + RuntimeLocalizableSaver.rootFolderName
            return bundlePath
        }()
        
        init() {
            try? createRootDirectoryIfNeeded()
        }
        
        func save(languageKey: LanguageKey, language: Language, tableName: String = Constants.defaultFileName) throws {
            try cleanRootContents()
            try write(languageKey: languageKey, language: language)
            
            currentLanguageKey = languageKey
        }
        
        func localizedString(for key: String) -> String? {
            if let currentLanguageKey {
                let filePath = rootFolderPath + "/\(currentLanguageKey).strings"
                let dictionary = NSDictionary(contentsOfFile: filePath) as? [String: String]
                if let string = dictionary?[key] {
                    return string
                }
            }

            return nil
        }
    }
}

private extension OwnID.CoreSDK.TranslationsSDK.RuntimeLocalizableSaver {
    var moduleEnglishBundlePath: String {
        languageBundlePath(language: Constants.enBundleName)
    }
    
    func createLprojDirectoryIfNeeded(_ lprojFilePath: String) throws {
        if !fileManager.fileExists(atPath: lprojFilePath) {
            do {
                try fileManager.createDirectory(atPath: lprojFilePath, withIntermediateDirectories: true)
            } catch let error {
                throw OwnID.CoreSDK.CoreErrorLogWrapper.coreLog(entry: .errorEntry(Self.self), error: .localizationManager(underlying: error))
            }
        }
    }
    
    func copyTranslatedFilesIfNeeded(_ lprojFilePath: String, _ moduleTranslations: String) throws {
        let localizableFilePath = lprojFilePath + "/Localizable.strings"
        if !fileManager.fileExists(atPath: localizableFilePath) {
            do {
                try fileManager.copyItem(atPath: moduleTranslations, toPath: localizableFilePath)
            } catch let error {
                throw OwnID.CoreSDK.CoreErrorLogWrapper.coreLog(entry: .errorEntry(Self.self), error: .localizationManager(underlying: error))
            }
        }
    }
    
    func languageBundlePath(language: String) -> String {
        rootFolderPath + "/" + language + "Translations." + Constants.bundleFileExtension
    }
    
    func cleanRootContents() throws {
        guard fileManager.fileExists(atPath: rootFolderPath) else { return }
        guard let filePaths = try? fileManager.contentsOfDirectory(atPath: rootFolderPath) else { return }
        for filePath in filePaths where filePath.contains(".\(Constants.bundleFileExtension)") {
            let fullFilePath = rootFolderPath + "/" + filePath
            do {
                try fileManager.removeItem(atPath: fullFilePath)
            } catch let error {
                throw OwnID.CoreSDK.CoreErrorLogWrapper.coreLog(entry: .errorEntry(Self.self), error: .localizationManager(underlying: error))
            }
        }
    }
    
    func createRootDirectoryIfNeeded() throws {
        if !fileManager.fileExists(atPath: rootFolderPath) {
            do {
                try fileManager.createDirectory(atPath: rootFolderPath, withIntermediateDirectories: true)
            } catch let error {
                throw OwnID.CoreSDK.CoreErrorLogWrapper.coreLog(entry: .errorEntry(Self.self), error: .localizationManager(underlying: error))
            }
        }
    }
    
    func write(languageKey: LanguageKey, language: Language) throws {
        let fileContentsString = language.reduce("", { $0 + "\"\($1.key)\" = \"\($1.value)\";\n" })
        
        let fileData = fileContentsString.data(using: .utf32)
        let filePath = rootFolderPath + "/\(languageKey).strings"
        fileManager.createFile(atPath: filePath, contents: fileData)
        let message = "Wrote bundle strings to languageKey \(languageKey)"
        OwnID.CoreSDK.logger.log(.entry(level: .debug, message: message, OwnID.CoreSDK.TranslationsSDK.RuntimeLocalizableSaver.self))
    }
}
