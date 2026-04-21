import Foundation

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
