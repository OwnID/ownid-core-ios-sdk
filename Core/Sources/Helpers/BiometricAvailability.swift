import LocalAuthentication
import Foundation

extension OwnID.CoreSDK {
    static var isPasskeysSupported: Bool {
        let isLeastPasskeysSupportediOS = ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 16, minorVersion: 0, patchVersion: 0))
        var isBiometricsAvailable = false
        let authContext = LAContext()
        let _ = authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch authContext.biometryType {
        case .none:
            break
        case .touchID:
            isBiometricsAvailable = true
        case .faceID:
            isBiometricsAvailable = true
        @unknown default:
            print("please update biometrics types")
        }
        let isPasscodeAvailable = LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        let isPasskeysSupported = isLeastPasskeysSupportediOS && (isBiometricsAvailable || isPasscodeAvailable)
        return isPasskeysSupported
    }
}
