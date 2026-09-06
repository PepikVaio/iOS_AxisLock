import Cocoa
import CoreGraphics

final class AxisLock {

    var is_Enabled: Bool = Defaults.default_Enabled

    var title_Launch_Key: list_Launch_Key = Defaults.default_Launch_Key

    var lock_Threshold: CGFloat = Defaults.default_Threshold
    var move_Sensitivity: CGFloat = Defaults.default_Sensitivity

    private var axis_Locked: list_Axis?
    private var eventTap: CFMachPort?

    private var is_Pressed_Launch_Key = false

    // Current cursor position
    private var cursor_X: CGFloat = 0
    private var cursor_Y: CGFloat = 0

    // Movement since pressing the activation key
    private var total_Delta_X: CGFloat = 0
    private var total_Delta_Y: CGFloat = 0

    enum list_Launch_Key: String {
        case control
        case shift
        case option
        case command
    }

    private enum list_Axis {
        case horizontal
        case vertical
    }

    func run_Stop() {

        if is_Pressed_Launch_Key {CGAssociateMouseAndMouseCursorPosition(1)}

        is_Pressed_Launch_Key = false
        axis_Locked = nil

        total_Delta_X = 0
        total_Delta_Y = 0

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            eventTap = nil
        }

    }

    func run_Start() {

        let mask =
            (CGEventMask(1) << CGEventType.flagsChanged.rawValue) |
            (CGEventMask(1) << CGEventType.mouseMoved.rawValue) |
            (CGEventMask(1) << CGEventType.leftMouseDragged.rawValue) |
            (CGEventMask(1) << CGEventType.rightMouseDragged.rawValue) |
            (CGEventMask(1) << CGEventType.otherMouseDragged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, refcon in

                guard let refcon else {
                    return Unmanaged.passUnretained(event)
                }

                let axisLock = Unmanaged<AxisLock>
                    .fromOpaque(refcon)
                    .takeUnretainedValue()

                return axisLock.handle(
                    type: type,
                    event: event
                )

            },

            userInfo: UnsafeMutableRawPointer(
                Unmanaged.passUnretained(self).toOpaque()
            )

        ) else {
            print("Failed to create event tap.")
            print("Allow the app in:")
            print("System Settings → Privacy & Security → Accessibility")
            return
        }

        eventTap = tap

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        print("list_Axis Lock is running.")
        print("Hold launch key and move the mouse.")

        if lock_Threshold == 0 {
            print("list_Axis: immediate lock.")
        } else {
            print("list_Axis detection threshold: \(lock_Threshold) px")
        }

        print("Movement sensitivity: \(Int(move_Sensitivity * 100)) %")

    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {

        switch type {
            case .tapDisabledByTimeout,
                .tapDisabledByUserInput:
                return Unmanaged.passUnretained(event)
            case .flagsChanged:
                handle_Changed_Flags(event)
                return Unmanaged.passUnretained(event)
            case .mouseMoved,
                .leftMouseDragged,
                .rightMouseDragged,
                .otherMouseDragged:
                return handle_Move_Mouse(event)
            default:
                return Unmanaged.passUnretained(event)
        }
    }

    private func handle_Changed_Flags(_ event: CGEvent) {

        let newActivationKeyState: Bool

        switch title_Launch_Key {
            case .control:
                newActivationKeyState = event.flags.contains(.maskControl)
            case .command:
                newActivationKeyState = event.flags.contains(.maskCommand)
            case .option:
                newActivationKeyState = event.flags.contains(.maskAlternate)
            case .shift:
                newActivationKeyState = event.flags.contains(.maskShift)
        }

        // Launch key pressed
        if newActivationKeyState && !is_Pressed_Launch_Key {

            is_Pressed_Launch_Key = true
            axis_Locked = nil

            total_Delta_X = 0
            total_Delta_Y = 0

            let position = CGEvent(source: nil)?.location
                ?? NSEvent.mouseLocation

            cursor_X = position.x
            cursor_Y = position.y

            // Separate the physical mouse from the cursor.
            CGAssociateMouseAndMouseCursorPosition(0)

            if lock_Threshold == 0 {
                print("Launch key → axis will lock on the first movement.")
            } else {
                print("Launch key → waiting for movement direction.")
            }
        }

        // Launch key released
        if !newActivationKeyState && is_Pressed_Launch_Key {

            is_Pressed_Launch_Key = false
            axis_Locked = nil

            total_Delta_X = 0
            total_Delta_Y = 0

            // Reconnect the physical mouse with the cursor.
            CGAssociateMouseAndMouseCursorPosition(1)
            print("list_Axis Lock disabled.")

        }

    }

    private func handle_Move_Mouse(_ event: CGEvent) -> Unmanaged<CGEvent>? {

        guard is_Enabled else {
            return Unmanaged.passUnretained(event)
        }

        guard is_Pressed_Launch_Key else {
            return Unmanaged.passUnretained(event)
        }

        // Actual physical mouse movement.
        let delta_X = CGFloat(
            event.getIntegerValueField(
                .mouseEventDeltaX
            )
        )

        let delta_Y = CGFloat(
            event.getIntegerValueField(
                .mouseEventDeltaY
            )
        )

        if delta_X == 0 && delta_Y == 0 {
            return nil
        }

        // list_Axis determination
        if axis_Locked == nil {

            // Mode without threshold:
            // the first movement immediately determines the axis.
            if lock_Threshold == 0 {

                if abs(delta_X) >= abs(delta_Y) {
                    axis_Locked = .horizontal
                    print("Horizontal axis locked")
                } else {
                    axis_Locked = .vertical
                    print("Vertical axis locked")
                }

            }

            // Mode with threshold: First accumulate movement.
            else {

                total_Delta_X += delta_X
                total_Delta_Y += delta_Y

                let absolute_Total_Delta_X = abs(total_Delta_X)
                let absolute_Total_Delta_Y = abs(total_Delta_Y)

                // Threshold has not been reached yet.
                if max(absolute_Total_Delta_X, absolute_Total_Delta_Y) < lock_Threshold {
                    return nil
                }

                // Select the dominant direction.
                if absolute_Total_Delta_X >= absolute_Total_Delta_Y {
                    axis_Locked = .horizontal
                    print("Horizontal axis locked")
                } else {
                    axis_Locked = .vertical
                    print("Vertical axis locked")
                }
            }
        }

        // Movement along the locked axis
        guard let axis = axis_Locked else {
            return nil
        }

        // Slow down the movement.
        let scaled_Delta_X = delta_X * move_Sensitivity
        let scaled_Delta_Y = delta_Y * move_Sensitivity

        switch axis {
            // Movement only left / right.
            case .horizontal: cursor_X += scaled_Delta_X
                CGWarpMouseCursorPosition(CGPoint(x: cursor_X, y: cursor_Y))
            // Movement only up / down.
            case .vertical: cursor_Y += scaled_Delta_Y
                CGWarpMouseCursorPosition(CGPoint(x: cursor_X, y: cursor_Y))
            }
            // Do not pass the original event further.
            return nil
    }

}
