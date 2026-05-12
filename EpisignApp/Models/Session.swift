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

        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm"
        let timeRange = "\(timeFmt.string(from: starts)) – \(timeFmt.string(from: ends))"

        let dayFmt = DateFormatter()
        let cal = Calendar.current
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

    // Sample data matching the HTML prototype
    static let samples: [CourseSession] = [
        CourseSession(
            id: "s1", code: "ALGO-402", name: "Advanced Algorithms",
            teacher: "Dr. Claire Moreau", room: "B-214",
            dateLabel: "Today", timeRange: "09:00 – 10:30",
            isLive: true, checkInStatus: .none
        ),
        CourseSession(
            id: "s2", code: "NET-301", name: "Network Architectures",
            teacher: "Prof. Julien Arnaud", room: "C-102",
            dateLabel: "Today", timeRange: "11:00 – 12:30",
            isLive: false, checkInStatus: .none
        ),
        CourseSession(
            id: "s3", code: "SEC-210", name: "Applied Cryptography",
            teacher: "Dr. Mira Osei", room: "A-309",
            dateLabel: "Today", timeRange: "14:00 – 15:30",
            isLive: false, checkInStatus: .none
        ),
        CourseSession(
            id: "s4", code: "DB-220", name: "Database Systems",
            teacher: "Prof. Samir Hadj", room: "B-108",
            dateLabel: "Tomorrow · Apr 22", timeRange: "08:30 – 10:00",
            isLive: false, checkInStatus: .none
        ),
        CourseSession(
            id: "s5", code: "ML-410", name: "Machine Learning Lab",
            teacher: "Dr. Léa Fontaine", room: "Lab-4",
            dateLabel: "Tomorrow · Apr 22", timeRange: "13:30 – 16:30",
            isLive: false, checkInStatus: .none
        ),
    ]

    var subjectPrefix: String { String(code.split(separator: "-").first ?? "") }
}
