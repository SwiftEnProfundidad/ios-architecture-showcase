import Foundation

public enum OperationalTimeFormatter {
    public static func hourMinute(
        from instant: Date,
        timeZoneIdentifier: String,
        locale: Locale = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = resolvedTimeZone(timeZoneIdentifier)
        formatter.setLocalizedDateFormatFromTemplate("HH:mm")
        return formatter.string(from: instant)
    }

    private static func resolvedTimeZone(_ identifier: String) -> TimeZone {
        TimeZone(identifier: identifier) ?? TimeZone(identifier: "UTC") ?? .current
    }
}
