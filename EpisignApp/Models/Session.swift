import Foundation

// MARK: - DB model (Supabase RPC response)

struct DBSession: Codable, Identifiable {
    let id: String
    let code: String
    let courseName: String
    let teacherName: String
    let room: String
    let startsAt: String
    let endsAt: String
    let slot: String
    let topic: String?

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case courseName  = "course_name"
        case teacherName = "teacher_name"
        case room
        case startsAt    = "starts_at"
        case endsAt      = "ends_at"
        case slot
        case topic
    }

    func toCourseSession() -> CourseSession {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoBasic = ISO8601DateFormatter()

        let now    = Date()
        let starts = iso.date(from: startsAt) ?? isoBasic.date(from: startsAt) ?? now
        let ends   = iso.date(from: endsAt)   ?? isoBasic.date(from: endsAt)   ?? now

        let isLive = now >= starts && now <= ends

        let paris = TimeZone(identifier: "Europe/Paris")!

        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm"
        timeFmt.timeZone = paris
        let timeRange = "\(timeFmt.string(from: starts)) – \(timeFmt.string(from: ends))"

        let dayFmt = DateFormatter()
        dayFmt.timeZone = paris
        var cal = Calendar.current
        cal.timeZone = paris
        let dateLabel: String
        if cal.isDateInToday(starts) {
            dateLabel = "Today"
        } else if cal.isDateInTomorrow(starts) {
            dayFmt.dateFormat = "d MMM"
            dateLabel = "Tomorrow · \(dayFmt.string(from: starts))"
        } else {
            dayFmt.dateFormat = "EEE d MMM"
            dateLabel = dayFmt.string(from: starts)
        }

        return CourseSession(
            id: id, code: code, name: courseName,
            teacher: teacherName, room: room,
            dateLabel: dateLabel, timeRange: timeRange,
            isLive: isLive, checkInStatus: .none
        )
    }
}

// MARK: - App model

struct CourseSession: Identifiable {
    let id: String
    let code: String
    let name: String
    let teacher: String
    let room: String
    let dateLabel: String
    let timeRange: String
    var isLive: Bool
    var checkInStatus: CheckInStatus

    enum CheckInStatus {
        case none, inProgress, done, late
    }

    var subjectPrefix: String { String(code.split(separator: "-").first ?? "") }
}
