public extension OwnID.CoreSDK {
    static let sdkName = String(describing: OwnID.CoreSDK.self)
    static let version = "2.2.0"
    static let APIVersion = "1"
}

public extension OwnID.CoreSDK {
    var environment: String? {
        store.value.firstConfiguration?.environment
    }
    
    var metricsURL: ServerURL? {
        store.value.firstConfiguration?.metricsURL
    }
    
    var supportedLocales: [String]? {
        store.value.firstConfiguration?.supportedLocales
    }
}

extension OwnID.CoreSDK {
    enum ConfigurationLoadingEvent {
        case loaded(LocalConfiguration)
        case error(Error)
    }
}
