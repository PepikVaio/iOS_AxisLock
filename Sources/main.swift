import Cocoa
import ServiceManagement
import ApplicationServices

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private let axisLock = AxisLock()
    private let localization = Localization.shared

    private var statusItem: NSStatusItem!

    private var item_Toggle: NSMenuItem!
    private var menu_Sensitivity: NSMenuItem!
    private var menu_Threshold: NSMenuItem!
    private var menu_Language: NSMenuItem!
    private var item_Launch_Login: NSMenuItem!
    private var menu_Launch_Key: NSMenuItem!

    private var accessibilityTimer: Timer!


    func applicationDidFinishLaunching(_ notification: Notification) {

        NSApp.setActivationPolicy(.accessory)
        load_Settings()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {

            if let resourceURL = Bundle.main.resourceURL?
                .appendingPathComponent("AxisLock_AxisLock.bundle"),

                let resourceBundle = Bundle(url: resourceURL),

                let url = resourceBundle.url(
                    forResource: "AxisLock-Status",
                    withExtension: "png"
                ),

                let image = NSImage(contentsOf: url) {

                button.image = image
            }
        }

        build_Menu()
        check_Accessibility(shouldEnable: axisLock.is_Enabled)
        update_Menu()
    }

    private func build_Menu() {

        let menu = NSMenu()

        // ABOUT
        let item_About = NSMenuItem(
            title: localization.get_Text("title_About"),
            action: #selector(show_About),
            keyEquivalent: ""
        )

        item_About.target = self
        menu.addItem(item_About)


        // ON / OFF
        item_Toggle = NSMenuItem(
            title: "",
            action: #selector(toggle_AxisLock),
            keyEquivalent: ""
        )

        item_Toggle.target = self
        menu.addItem(item_Toggle)
        menu.addItem(.separator())


        // Sensitivity
        menu_Sensitivity = NSMenuItem(
            title: localization.get_Text("title_Sensitivity"),
            action: nil,
            keyEquivalent: ""
        )

        let submenu_Sensitivity = NSMenu()

        let submenu_Items_Sensitivity: [(String, CGFloat)] = [
            ("10 %", 0.10),
            ("20 %", 0.20),
            ("30 %", 0.30),
            ("40 %", 0.40),
            ("50 %", 0.50),
            ("60 %", 0.60),
            ("70 %", 0.70),
            ("80 %", 0.80),
            ("90 %", 0.90),
            ("100 %", 1.00)
        ]

        for (title, value) in submenu_Items_Sensitivity {

            let item = NSMenuItem(
                title: title,
                action: #selector(set_Sensitivity(_:)),
                keyEquivalent: ""
            )

            item.target = self
            item.representedObject = value

            if value == axisLock.move_Sensitivity {item.state = .on}
            submenu_Sensitivity.addItem(item)

        }

        menu_Sensitivity.submenu = submenu_Sensitivity
        menu.addItem(menu_Sensitivity)


        // Threshold
        menu_Threshold = NSMenuItem(
            title: localization.get_Text("title_Threshold"),
            action: nil,
            keyEquivalent: ""
        )

        let submenu_Threshold = NSMenu()

        let sumbenu_Items_Threshold: [(String, CGFloat)] = [
            ("0 px", 0),
            ("1 px", 1),
            ("2 px", 2),
            ("3 px", 3),
            ("5 px", 5),
            ("7 px", 7),
            ("10 px", 10)
        ]

        for (title, value) in sumbenu_Items_Threshold {

            let item = NSMenuItem(
                title: title,
                action: #selector(set_Threshold(_:)),
                keyEquivalent: ""
            )

            item.target = self
            item.representedObject = value

            if value == axisLock.lock_Threshold {item.state = .on}
            submenu_Threshold.addItem(item)

        }

        menu_Threshold.submenu = submenu_Threshold
        menu.addItem(menu_Threshold)


        // Launch_Key
        menu_Launch_Key = NSMenuItem(
            title: localization.get_Text("title_Launch_Key"),
            action: nil,
            keyEquivalent: ""
        )

        let submenu_Launch_Key = NSMenu()

        let submenu_Items_Launch_Key: [(String, AxisLock.list_Launch_Key)] = [
            ("⌃ Ctrl", .control),
            ("⇧ Shift", .shift),
            ("⌥ Option", .option),
            ("⌘ Command", .command)
        ]

        for (title, key) in submenu_Items_Launch_Key {

            let item = NSMenuItem(
                title: title,
                action: #selector(set_Launch_Key(_:)),
                keyEquivalent: ""
            )

            item.target = self
            item.representedObject = key
            submenu_Launch_Key.addItem(item)

        }

        menu_Launch_Key.submenu = submenu_Launch_Key
        menu.addItem(menu_Launch_Key)


        // Language
        menu_Language = NSMenuItem(
            title: localization.get_Text("title_Language"),
            action: nil,
            keyEquivalent: ""
        )

        let sumbenu_Language = NSMenu()

        let item_English = NSMenuItem(
            title: localization.get_Text("subtitle_English"),
            action: #selector(set_English),
            keyEquivalent: ""
        )

        item_English.target = self
        item_English.representedObject = list_AppLanguage.en

        if localization.title_Language == .en {item_English.state = .on}

        sumbenu_Language.addItem(item_English)

        let item_Czech = NSMenuItem(
            title: localization.get_Text("subtitle_Czech"),
            action: #selector(set_Czech),
            keyEquivalent: ""
        )

        item_Czech.target = self
        item_Czech.representedObject = list_AppLanguage.cs

        if localization.title_Language == .cs {item_Czech.state = .on}

        sumbenu_Language.addItem(item_Czech)

        menu_Language.submenu = sumbenu_Language
        menu.addItem(menu_Language)
        menu.addItem(.separator())


        // Launch_Login
        item_Launch_Login = NSMenuItem(
            title: localization.get_Text("title_Launch_Login"),
            action: #selector(toggle_Launch_Login),
            keyEquivalent: ""
        )

        item_Launch_Login.target = self
        menu.addItem(item_Launch_Login)


        // Reset
        let item_Reset = NSMenuItem(
            title: localization.get_Text("title_Reset"),
            action: #selector(title_Reset),
            keyEquivalent: ""
        )

        item_Reset.target = self
        menu.addItem(item_Reset)
        menu.addItem(.separator())


        // Quit
        let item_Quit = NSMenuItem(
            title: localization.get_Text("title_Quit"),
            action: #selector(title_Quit),
            keyEquivalent: "q"
        )

        item_Quit.target = self
        menu.addItem(item_Quit)
        statusItem.menu = menu
        update_Activation_Key()

    }

    private func check_Accessibility(shouldEnable: Bool) {

        if AXIsProcessTrusted() {

            if shouldEnable {
                axisLock.is_Enabled = true
                axisLock.run_Start()
            }

            update_Menu()
            return

        }

        axisLock.is_Enabled = false
        update_Menu()

        let alert = NSAlert()

        alert.messageText = localization.get_Text("window_Alert_Title")
        alert.informativeText = localization.get_Text("window_Alert_Text")
        alert.alertStyle = .warning

        alert.addButton(withTitle: localization.get_Text("button_Open"))
        alert.addButton(withTitle: localization.get_Text("button_Later"))

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {

            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")

            if let url {NSWorkspace.shared.open(url)}

            wait_Accessibility()

        } else {

            axisLock.is_Enabled = false
            update_Menu()

        }

    }

    private func load_Settings() {

        let defaults = UserDefaults.standard

        if defaults.object(forKey: "AxisLock.is_Enabled") != nil {
            axisLock.is_Enabled = defaults.bool(forKey: "AxisLock.is_Enabled")
        } else {
            axisLock.is_Enabled = Defaults.default_Enabled
        }

        if defaults.object(forKey: "AxisLock.move_Sensitivity") != nil {
            axisLock.move_Sensitivity = CGFloat(defaults.double(forKey: "AxisLock.move_Sensitivity"))
        } else {
            axisLock.move_Sensitivity = Defaults.default_Sensitivity
        }

        if defaults.object(forKey: "AxisLock.lock_Threshold") != nil {
            axisLock.lock_Threshold = CGFloat(defaults.double(forKey: "AxisLock.lock_Threshold"))
        } else {
            axisLock.lock_Threshold = Defaults.default_Threshold
        }

        if let savedKey = UserDefaults.standard.string(forKey: "AxisLock.title_Launch_Key") {
            axisLock.title_Launch_Key = AxisLock.list_Launch_Key(rawValue: savedKey) ?? .command
        } else {
            axisLock.title_Launch_Key = .control
        }

    }

    private func rebuild_Menu() {
        build_Menu()
        update_Menu()
    }

    private func save_Settings() {

        let defaults = UserDefaults.standard

        defaults.set(axisLock.is_Enabled, forKey: "AxisLock.is_Enabled")
        defaults.set(Double(axisLock.move_Sensitivity), forKey: "AxisLock.move_Sensitivity")
        defaults.set(Double(axisLock.lock_Threshold), forKey: "AxisLock.lock_Threshold")

    }

    @objc private func set_Czech() {
        localization.set_Language(.cs)
        rebuild_Menu()
    }

    @objc private func set_English() {
        localization.set_Language(.en)
        rebuild_Menu()
    }

    @objc private func set_Launch_Key(_ sender: NSMenuItem) {

        guard let key =
            sender.representedObject as? AxisLock.list_Launch_Key
        else {
            return
        }

        axisLock.title_Launch_Key = key

        UserDefaults.standard.set(
            key.rawValue,
            forKey: "AxisLock.title_Launch_Key"
        )

        update_Activation_Key()

    }

    @objc private func set_Sensitivity(_ sender: NSMenuItem) {

        guard let value =
            sender.representedObject as? CGFloat
        else {
            return
        }

        axisLock.move_Sensitivity = value

        save_Settings()
        update_Sensitivity()

        print("Threshold set to (value) px")

    }

    @objc private func set_Threshold(_ sender: NSMenuItem) {

        guard let value =
            sender.representedObject as? CGFloat
        else {
            return
        }

        axisLock.lock_Threshold = value

        save_Settings()
        update_Threshold()


        print("Threshold set to (value) px")

    }

    @objc private func show_About() {

        if let resourceURL = Bundle.main.resourceURL?
            .appendingPathComponent("AxisLock_AxisLock.bundle"),
        let resourceBundle = Bundle(url: resourceURL),
        let url = resourceBundle.url(forResource: "AxisLock-About", withExtension: "png"),
        let image = NSImage(contentsOf: url) {NSApp.applicationIconImage = image}
        let options: [NSApplication.AboutPanelOptionKey: Any] = [
            .applicationName: localization.get_Text("title_App"),
            .applicationVersion: "1.0.0",
            .credits: NSAttributedString(string: localization.get_Text("window_About_Text"))
        ]

        NSApp.orderFrontStandardAboutPanel(options: options)
        NSApp.activate(ignoringOtherApps: true)

    }

    @objc private func title_Quit() {
        axisLock.run_Stop()
        NSApp.terminate(nil)
    }

    @objc private func title_Reset() {

        let alert = NSAlert()

        alert.messageText = localization.get_Text("windoew_Reset_Title")
        alert.informativeText = localization.get_Text("windoew_Reset_Text")
        alert.alertStyle = .warning

        alert.addButton(withTitle: localization.get_Text("button_OK"))
        alert.addButton(withTitle: localization.get_Text("button_Cancel"))

        let response = alert.runModal()

        guard response == 
                .alertFirstButtonReturn
        else {
            return
        }

        axisLock.run_Stop()

        axisLock.is_Enabled = Defaults.default_Enabled
        axisLock.move_Sensitivity = Defaults.default_Sensitivity
        axisLock.lock_Threshold = Defaults.default_Threshold
        axisLock.title_Launch_Key = Defaults.default_Launch_Key
        localization.set_Language(Defaults.default_Language)

        if Defaults.default_Launch_Login {

            if SMAppService.mainApp.status != .enabled {
                try? SMAppService.mainApp.register()
            }

        } else {

            if SMAppService.mainApp.status == .enabled {
                try? SMAppService.mainApp.unregister()
            }

        }

        UserDefaults.standard.set(
            Defaults.default_Launch_Key.rawValue,
            forKey: "AxisLock.title_Launch_Key"
        )

        save_Settings()
        rebuild_Menu()

        print("Default settings restored.")

    }

    @objc private func toggle_AxisLock() {

        if axisLock.is_Enabled {

            axisLock.is_Enabled = false
            axisLock.run_Stop()

            accessibilityTimer?.invalidate()
            accessibilityTimer = nil

            save_Settings()
            update_Menu()

            return

        }

        check_Accessibility(shouldEnable: true)

    }

    @objc private func toggle_Launch_Login() {

        do {

            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
                print("Launch at login disabled.")
            } else {
                try SMAppService.mainApp.register()
                print("Launch at login enabled.")
            }

            update_Launch_Login()

        } catch {
            print("Failed to change launch at login: \(error)")
        }

    }

    private func update_Activation_Key() {

        guard let submenu =
            menu_Launch_Key.submenu
        else {
            return
        }

        for item in submenu.items {

            guard let key =
                item.representedObject as? AxisLock.list_Launch_Key
            else {
                continue
            }

            if key == axisLock.title_Launch_Key {
                item.state = .on
            } else {
                item.state = .off
            }

        }

    }

    private func update_Launch_Login() {

        if SMAppService.mainApp.status == .enabled {
            item_Launch_Login.state = .on
        } else {
            item_Launch_Login.state = .off
        }

    }

    private func update_Menu() {

        let text_Status = localization.get_Text_Status(axisLock.is_Enabled)

        item_Toggle.title = text_Status.prefix(1).uppercased() + text_Status.dropFirst()
        item_Toggle.state = axisLock.is_Enabled ? .on : .off

        update_Launch_Login()

    }

    private func update_Sensitivity() {

        guard let submenu =
            menu_Sensitivity.submenu
        else {
            return
        }

        for item in submenu.items {

            guard let value =
                item.representedObject as? CGFloat
            else {
                continue
            }

            if value == axisLock.move_Sensitivity {
                item.state = .on
            } else {
                item.state = .off
            }
        }

    }

    private func update_Threshold() {

        guard let submenu =
            menu_Threshold.submenu
        else {
            return
        }

        for item in submenu.items {

            guard let value =
                item.representedObject as? CGFloat
            else {
                continue
            }

            if value == axisLock.lock_Threshold {
                item.state = .on
            } else {
                item.state = .off
            }

        }

    }

    private func wait_Accessibility() {

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1.0
        ) { [weak self] in

            guard let self else {
                return
            }

            if AXIsProcessTrusted() {

                self.update_Menu()
                return

            }

            self.axisLock.is_Enabled = false
            self.update_Menu()
            self.wait_Accessibility()

        }

    }

}

let app = NSApplication.shared
let delegate = AppDelegate()

app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
