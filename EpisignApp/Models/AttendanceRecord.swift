import Foundation

struct AttendanceRecord: Identifiable {
    let id: String
    let sessionCode: String
    let sessionName: String
    let date: String
    let status: Status
    let justification: String?

    enum Status {
        case attended, late, absentJustified, absentUnjustified

        var label: String {
            switch self {
            case .attended:          return "Attended"
            case .late:              return "Late"
            case .absentJustified:   return "Justified"
            case .absentUnjustified: return "Unjustified"
            }
        }
    }

    static let samples: [AttendanceRecord] = [
        AttendanceRecord(id: "r1", sessionCode: "ALGO-402", sessionName: "Advanced Algorithms",   date: "Apr 19", status: .attended,          justification: nil),
        AttendanceRecord(id: "r2", sessionCode: "NET-301",  sessionName: "Network Architectures",  date: "Apr 18", status: .late,              justification: nil),
        AttendanceRecord(id: "r3", sessionCode: "DB-220",   sessionName: "Database Systems",       date: "Apr 15", status: .absentJustified,    justification: "Medical"),
        AttendanceRecord(id: "r4", sessionCode: "ML-410",   sessionName: "Machine Learning Lab",   date: "Apr 12", status: .absentUnjustified,  justification: nil),
        AttendanceRecord(id: "r5", sessionCode: "ALGO-402", sessionName: "Advanced Algorithms",    date: "Apr 11", status: .attended,           justification: nil),
    ]
}

struct AttendanceSummary {
    let total: Int
    let attended: Int
    let late: Int
    let absentJustified: Int
    let absentUnjustified: Int

    var presentCount: Int { attended + late }

    var percentage: Int {
        guard total > 0 else { return 0 }
        return Int(Double(presentCount) / Double(total) * 100)
    }

    static let sample = AttendanceSummary(
        total: 53, attended: 47, late: 3, absentJustified: 2, absentUnjustified: 1
    )

    static let weeklyTrend: [Int] = [92, 100, 88, 96, 100, 80, 100, 96, 92, 100, 100, 96]
}
