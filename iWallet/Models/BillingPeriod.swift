import Foundation

extension BillingPeriod {
    func advanced(by months: Int, salaryDay: Int, calendar: Calendar = .current) -> BillingPeriod {
        let shiftedStart = calendar.date(byAdding: .month, value: months, to: start)!
        return BillingPeriod.containing(date: shiftedStart, salaryDay: salaryDay, calendar: calendar)
    }

    /// Generates the last `count` periods (most recent first), for the dropdown list.
    static func recentPeriods(count: Int, salaryDay: Int, calendar: Calendar = .current) -> [BillingPeriod] {
        let current = BillingPeriod.containing(date: .now, salaryDay: salaryDay, calendar: calendar)
        return (0..<count).map { current.advanced(by: -$0, salaryDay: salaryDay, calendar: calendar) }
    }
}

struct BillingPeriod {
    let start: Date
    let end: Date

    static func containing(date: Date, salaryDay: Int, calendar: Calendar = .current) -> BillingPeriod {
        var comps = calendar.dateComponents([.year, .month, .day], from: date)
        let day = comps.day ?? 1

        var startComps = comps
        startComps.day = salaryDay
        if day < salaryDay {
            startComps.month = (startComps.month ?? 1) - 1
        }
        let start = calendar.date(from: startComps)!

        let end = calendar.date(byAdding: .month, value: 1, to: start)!
        let adjustedEnd = calendar.date(byAdding: .day, value: -1, to: end)!

        return BillingPeriod(start: start, end: adjustedEnd)
    }
}
