import SwiftUI

enum Tab: CaseIterable {
    case home, schedule, attendance, profile

    var label: String {
        switch self {
        case .home:       return "Today"
        case .schedule:   return "Schedule"
        case .attendance: return "Attendance"
        case .profile:    return "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home:       return "house.fill"
        case .schedule:   return "calendar"
        case .attendance: return "chart.bar.fill"
        case .profile:    return "person.circle.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selected: Tab = .home

    var body: some View {
        TabView(selection: $selected) {
            DashboardView()
                .tabItem {
                    Label(Tab.home.label, systemImage: Tab.home.systemImage)
                }
                .tag(Tab.home)

            ScheduleView()
                .tabItem {
                    Label(Tab.schedule.label, systemImage: Tab.schedule.systemImage)
                }
                .tag(Tab.schedule)

            AttendanceView()
                .tabItem {
                    Label(Tab.attendance.label, systemImage: Tab.attendance.systemImage)
                }
                .tag(Tab.attendance)

            ProfileView()
                .tabItem {
                    Label(Tab.profile.label, systemImage: Tab.profile.systemImage)
                }
                .tag(Tab.profile)
        }
        .accentColor(.forgeBrand)
    }
}

// Placeholder Schedule tab — same as dashboard but filtered to weekly view
struct ScheduleView: View {
    var body: some View {
        DashboardView(initialFilter: .schedule)
    }
}
