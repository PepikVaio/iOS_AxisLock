import Foundation

enum list_AppLanguage: String {
    case en
    case cs
}

@MainActor
final class Localization {

    static let shared = Localization()

    private let languageKey = "AxisLock.title_Language"
    private(set) var title_Language: list_AppLanguage = Defaults.default_Language
    private init() {load_Language()}

    func get_Text(_ key: String) -> String {

        if key == "windoew_Reset_Text" {

            switch title_Language {
                case .cs:
                    return get_Text_Reset_CS()
                case .en:
                    return get_Text_Reset_EN()
            }

        }

        switch title_Language {
            case .cs:
                return subtitle_Czech[key] ?? key
            case .en:
                return subtitle_English[key] ?? key
        }

    }

    private func get_Text_Reset_EN() -> String {

        let text_Enabled = get_Text_Status(Defaults.default_Enabled)
        let text_Launch_Login = get_Text_Status(Defaults.default_Launch_Login)

        return
            "AxisLock will be restored to its default settings:\n\n" +
            "AxisLock: \(text_Enabled)\n" +
            "Sensitivity: \(Int(Defaults.default_Sensitivity * 100)) %\n" +
            "Axis detection threshold: \(Int(Defaults.default_Threshold)) px\n" +
            "Activation key: \(Defaults.default_Launch_Key)\n" +
            "Language: \(Defaults.default_Language)\n" +
            "Launch at login: \(text_Launch_Login)"

    }

    private func get_Text_Reset_CS() -> String {

        let text_Enabled = get_Text_Status(Defaults.default_Enabled)
        let text_Launch_Login = get_Text_Status(Defaults.default_Launch_Login)

        return
            "AxisLock se vrátí na výchozí hodnoty:\n\n" +
            "AxisLock: \(text_Enabled)\n" +
            "Citlivost: \(Int(Defaults.default_Sensitivity * 100)) %\n" +
            "Práh určení osy: \(Int(Defaults.default_Threshold)) px\n" +
            "Spouštěcí klávesa: \(Defaults.default_Launch_Key)\n" +
            "Jazyk: \(Defaults.default_Language)\n" +
            "Spustit po přihlášení: \(text_Launch_Login)"
            

    }

    func get_Text_Status(_ value: Bool) -> String {

        switch title_Language {
            case .cs:
                return value ? "povoleno" : "zakázáno"
            case .en:
                return value ? "enabled" : "disabled"
        }

    }

    private func load_Language() {

        guard let language_Saved =
            UserDefaults.standard.string(
                forKey: languageKey
            ) else {
                title_Language = Defaults.default_Language
                return
            }

        title_Language = list_AppLanguage(rawValue: language_Saved) ?? Defaults.default_Language

    }

    func set_Language(_ title_Language: list_AppLanguage) {

        self.title_Language = title_Language

        UserDefaults.standard.set(
            title_Language.rawValue,
            forKey: languageKey
        )

    }


    private let subtitle_English: [String: String] = [

        "title_App": "AxisLock",
        "title_About": "About AxisLock",


        "title_Sensitivity": "Sensitivity",
        "title_Threshold": "Axis detection threshold",
        "title_Launch_Key": "Activation key",
        "title_Language": "Language",

            "subtitle_English": "English",
            "subtitle_Czech": "Czech",


        "title_Launch_Login": "Launch at login",
        "title_Reset": "Restore default settings",


        "title_Quit": "Quit AxisLock",


        "window_Alert_Title": "AxisLock needs permission",
        "window_Alert_Text": "AxisLock needs accessibility permission to function correctly and respond to mouse movement and key presses.",

            "button_Open": "Open settings",
            "button_Later": "Later",


        "window_About_Text":
            "Keeps mouse movement precisely aligned horizontally or vertically.\n\n" +
            "Hold the selected key and move the mouse.\n\n" +
            "Release the key to restore normal mouse movement.",


        "windoew_Reset_Title": "Restore default settings?",

            "button_OK": "Restore",
            "button_Cancel": "Cancel"

    ]

    private let subtitle_Czech: [String: String] = [

        "title_App": "AxisLock",
        "title_About": "O aplikaci AxisLock",


        "title_Sensitivity": "Citlivost",
        "title_Threshold": "Práh určení osy",
        "title_Launch_Key": "Spouštěcí klávesa",
        "title_Language": "Jazyk",

            "subtitle_English": "Angličtina",
            "subtitle_Czech": "Čeština",

        "title_Launch_Login": "Spustit po přihlášení",
        "title_Reset": "Obnovit výchozí nastavení",


        "title_Quit": "Ukončit AxisLock",


        "window_Alert_Title": "AxisLock potřebuje oprávnění",
        "window_Alert_Text": "Pro správné fungování potřebuje AxisLock oprávnění zpřístupnění, aby mohl reagovat na pohyb myši a stisk klávesy.",


        "window_About_Text":
            "Udržuje pohyb myši přesně ve vodorovném nebo svislém směru.\n\n" +
            "Podržte vybranou klávesu a pohybujte myší.\n\n" +
            "Po uvolnění klávesy se pohyb myši obnoví do výchozího stavu.",

            "button_Open": "Otevřít nastavení",
            "button_Later": "Později",


        "windoew_Reset_Title":
            "Obnovit výchozí nastavení?",

            "button_OK": "Obnovit",
            "button_Cancel": "Zrušit"

    ]

}
