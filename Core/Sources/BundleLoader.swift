//
//  BundleLoader.swift
//  ownid-core-ios-sdk
//
//  Created by W on 10/7/22.
//

import Foundation

class OwnIDCoreSDK { }

extension Bundle {
    static let resourceBundle: Bundle = {
        let myBundle = Bundle(for: OwnIDCoreSDK.self)

        guard let resourceBundleURL = myBundle.url(
            forResource: String(describing: OwnIDCoreSDK.self), withExtension: "bundle")
            else { fatalError(".bundle not found!") }

        guard let resourceBundle = Bundle(url: resourceBundleURL)
            else { fatalError("Cannot access .bundle!") }

        return resourceBundle
    }()
}
