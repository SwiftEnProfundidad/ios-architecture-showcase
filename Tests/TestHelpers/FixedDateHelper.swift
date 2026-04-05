import Foundation

func fixedDate(hour: Int, minute: Int) -> Date {
    guard let date = Calendar(identifier: .gregorian).date(
        from: DateComponents(
            timeZone: TimeZone(secondsFromGMT: 0),
            year: 2030,
            month: 3,
            day: 10,
            hour: hour,
            minute: minute
        )
    ) else {
        preconditionFailure("fixedDate: static calendar components must resolve to a valid instant")
    }
    return date
}
