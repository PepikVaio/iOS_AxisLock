import Foundation

enum Defaults {

    // AxisLock is enabled by default
    static let default_Enabled = false

    // Movement sensitivity after locking the axis
    // 1.00 = original speed
    // 0.50 = 50 % of the original speed
    // 0.35 = 35 % of the original speed
    // ...
    static let default_Sensitivity: CGFloat = 0.50

    // Threshold for determining the axis in pixels
    // 0  = axis locks immediately on the first movement
    // 10 = axis is determined after 10 px of movement
    // 20 = axis is determined after 20 px of movement
    // ...
    static let default_Threshold: CGFloat = 3

    // Modifier key used to activate AxisLock
    static let default_Launch_Key: AxisLock.list_Launch_Key = .control

    // Default application language
    static let default_Language: list_AppLanguage = .en

    // Start AxisLock automatically after login
    static let default_Launch_Login = false
}
