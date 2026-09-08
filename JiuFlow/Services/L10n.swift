import Foundation

/// Dictionary-based UI localization keyed by the Japanese source string.
///
/// `tr("記録する")` returns the English / Portuguese translation from `Localizations.json`
/// (bundled) according to the in-app language (`preferred_language`, same key as
/// `LanguageManager`). Missing entries fall back to the Japanese source, so an untranslated
/// string is never blank. `ContentView` is re-created via `.id(lang.current)` when the
/// language changes, so views that only call `tr()` still re-render.
enum L10n {
    /// ja → ["en": ..., "pt": ...]
    static let table: [String: [String: String]] = {
        guard let url = Bundle.main.url(forResource: "Localizations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: [String: String]]
        else { return [:] }
        return obj
    }()

    static var language: String {
        UserDefaults.standard.string(forKey: "preferred_language") ?? "ja"
    }

    static func t(_ ja: String, lang: String? = nil) -> String {
        let l = lang ?? language
        if l == "ja" { return ja }
        guard let row = table[ja] else { return ja }
        if let v = row[l], !v.isEmpty { return v }
        if l == "pt", let en = row["en"], !en.isEmpty { return en }   // pt falls back to en
        return ja
    }
}

extension L10n {
    /// Locale for date/number formatting that follows the in-app language.
    static var locale: Locale {
        switch language {
        case "en": return Locale(identifier: "en_US")
        case "pt": return Locale(identifier: "pt_BR")
        default:   return Locale(identifier: "ja_JP")
        }
    }
}

/// Short form used throughout the views.
@inline(__always)
func tr(_ ja: String) -> String { L10n.t(ja) }

/// Format-string variant: `trf("今週 %ld/%ld", done, goal)`. Translations keep the same
/// `%ld` / `%@` placeholders (positional `%1$@` allowed when word order changes).
func trf(_ ja: String, _ args: CVarArg...) -> String {
    String(format: L10n.t(ja), locale: L10n.locale, arguments: args)
}
