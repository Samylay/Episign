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
}
