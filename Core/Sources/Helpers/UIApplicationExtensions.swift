//
//  UIApplicationExtensions.swift
//  ownid-core-ios-sdk
//
//  Created by user on 19.07.2023.
//

import UIKit

@available(iOS 15.0, *)
extension UIApplication {
    static var window: UIWindow {
        let scene = UIApplication.shared.connectedScenes.first
        return (scene as? UIWindowScene)?.keyWindow ?? UIWindow()
    }
    
    static func topViewController(controller: UIViewController? =
                                  window.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}