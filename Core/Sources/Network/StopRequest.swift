//
//  FinalStopRequest.swift
//  ownid-core-ios-sdk
//
//  Created by user on 18.05.2023.
//

import Foundation
import Combine

public extension OwnID.CoreSDK {
    enum Stop {}
}

extension OwnID.CoreSDK.Stop {
    class Request {
        let url: OwnID.CoreSDK.ServerURL
        let provider: APIProvider
        let supportedLanguages: OwnID.CoreSDK.Languages
        
        private var bag = Set<AnyCancellable>()
        
        internal init(url: OwnID.CoreSDK.ServerURL,
                      supportedLanguages: OwnID.CoreSDK.Languages,
                      provider: APIProvider = URLSession.shared) {
            self.url = url
            self.provider = provider
            self.supportedLanguages = supportedLanguages
        }
        
        func perform() -> AnyPublisher<Data, OwnID.CoreSDK.CoreErrorLogWrapper> {
            let request = URLRequest.defaultPostRequest(url: url, body: Data(), supportedLanguages: supportedLanguages)

            return provider.apiResponse(for: request)
                .map(\.data)
                .mapError { error in
                    OwnID.CoreSDK.CoreErrorLogWrapper.coreLog(entry: .errorEntry(Self.self),
                                                              error: .initRequestResponseDecodeFailed(underlying: error))
                }
                .eraseToAnyPublisher()
        }
    }
}
