import Foundation

public enum AppStrings {
    public static func localized(_ key: String) -> String {
        let resolved = String(localized: String.LocalizationValue(key), bundle: .module)
        if resolved != key {
            return resolved
        }
        return CatalogFallbackStorage.value(for: key) ?? key
    }

    public static func localized(_ key: String, _ arguments: String...) -> String {
        arguments.reduce(localized(key)) { partialResult, argument in
            guard let range = partialResult.range(of: "%@") else {
                return partialResult
            }
            var updated = partialResult
            updated.replaceSubrange(range, with: argument)
            return updated
        }
    }
}

private enum CatalogFallbackStorage {
    private static let strings = loadStrings()

    static func value(for key: String) -> String? {
        let languageCode = Locale.preferredLanguages
            .first?
            .split(separator: "-")
            .first
            .map(String.init) ?? "en"
        return strings[key]?[languageCode] ?? strings[key]?["en"]
    }

    private static func loadStrings() -> [String: [String: String]] {
        guard
            let url = Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings"),
            let data = try? Data(contentsOf: url),
            let catalog = try? JSONDecoder().decode(StringCatalog.self, from: data)
        else {
            return [:]
        }
        return catalog.strings.mapValues { entry in
            entry.localizations.mapValues(\.stringUnit.value)
        }
    }
}

private struct StringCatalog: Decodable {
    let strings: [String: StringCatalogEntry]
}

private struct StringCatalogEntry: Decodable {
    let localizations: [String: StringCatalogLocalization]
}

private struct StringCatalogLocalization: Decodable {
    let stringUnit: StringCatalogStringUnit
}

private struct StringCatalogStringUnit: Decodable {
    let value: String
}
