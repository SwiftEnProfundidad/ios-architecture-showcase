import Foundation

func fixedDate(hour: Int, minute: Int) -> Date {
    Calendar(identifier: .gregorian).date(
        from: DateComponents(
            timeZone: TimeZone(secondsFromGMT: 0),
            year: 2030,
            month: 3,
            day: 10,
            hour: hour,
            minute: minute
        )
    )!
}
