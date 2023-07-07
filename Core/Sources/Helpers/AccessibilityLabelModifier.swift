//
//  AccessibilityLabelModifier.swift
//  ownid-core-ios-sdk
//
//  Created by user on 06.07.2023.
//

import SwiftUI

struct AccessibilityLabelModifier: ViewModifier {
    let accessibilityLabel: String
    
    func body(content: Content) -> some View {
        if #available(iOS 14.0, *) {
            content.accessibilityLabel(accessibilityLabel)
        }
    }
}