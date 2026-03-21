import SwiftUI

@MainActor
class LanguageManager: ObservableObject {
    @AppStorage("preferred_language") var current: String = "ja" {
        didSet { objectWillChange.send() }
    }

    func t(_ ja: String, en: String, pt: String = "") -> String {
        switch current {
        case "en": return en
        case "pt": return pt.isEmpty ? en : pt
        default: return ja
        }
    }
}

// Convenience for static access
struct L {
    static func tab(_ key: String, lang: String) -> String {
        let map: [String: [String: String]] = [
            "home": ["ja": "ホーム", "en": "Home", "pt": "Inicio"],
            "technique": ["ja": "テクニック", "en": "Technique", "pt": "Tecnica"],
            "videos": ["ja": "動画", "en": "Videos", "pt": "Videos"],
            "dojos": ["ja": "道場", "en": "Dojos", "pt": "Dojos"],
            "mypage": ["ja": "マイページ", "en": "My Page", "pt": "Minha Pagina"],
        ]
        return map[key]?[lang] ?? map[key]?["ja"] ?? key
    }
}
