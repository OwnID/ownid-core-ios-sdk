import Foundation
import Combine

extension OwnID.CoreSDK {
    struct SDKState: LoggingEnabled {
        var isLoggingEnabled = false
        var configurations = [String: OwnID.CoreSDK.LocalConfiguration]()
        var clientConfiguration: ClientConfiguration?
        let configurationLoadedPublisher: PassthroughSubject<ClientConfiguration, Never>
        var supportedLanguages: OwnID.CoreSDK.Languages = .init(rawValue: ["en"])
    }
}

extension OwnID.CoreSDK.SDKState {
    var configurationName: String {
        configurations.first!.key
    }
    
    func getConfiguration(for sdkConfigurationName: String) -> OwnID.CoreSDK.LocalConfiguration {
        guard let config = configurations[sdkConfigurationName] else { fatalError("Configuration does not exist for name") }
        return config
    }
}
