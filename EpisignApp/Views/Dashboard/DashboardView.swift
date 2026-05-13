import SwiftUI

enum DashboardFilter: CaseIterable {
    case today, upcoming, schedule

    var label: String {
        switch self {
        case .today:    return "Today"
        case .upcoming: return "Upcoming"
        case .schedule: return "Schedule"
        }
    }
}

struct DashboardView: View {
    var initialFilter: DashboardFilter = .today

    @EnvironmentObject var auth: AuthService
    @State private var filter: DashboardFilter = .today
    @State private var sessions: [CourseSession] = []
    @State private var selected: CourseSession?
    @State private var showDetail = false
    @State private var isLoading = false
    @State private var loadingError: String?

    var displayedSessions: [CourseSession] {
        switch filter {
        case .today:    return sessions.filter { $0.dateLabel.hasPrefix("Today") }
        case .upcoming, .schedule: return sessions
        }
    }

    @State private var showNotifications = false

    private var todayDayName: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        f.timeZone = TimeZone(identifier: "Europe/Paris")
        return f.string(from: Date())
    }

    private var todayDateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "d MMMM"
        f.timeZone = TimeZone(identifier: "Europe/Paris")
        return f.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.forgeBg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        // Date header
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(todayDayName), \(todayDateLabel)")
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundColor(.forgeMuted)
                            Text("Today")
                                .font(.system(size: 28, weight: .bold))
                                .kerning(-0.7)
                                .foregroundColor(.forgeInk)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Filter pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(DashboardFilter.allCases, id: \.self) { f in
                                    FilterChip(label: f.label, active: filter == f) {
                                        withAnimation(.spring(response: 0.25)) { filter = f }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Session cards
                        if isLoading {
                            ProgressView()
                                .padding(.top, 48)
                        } else if displayedSessions.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 38))
                                    .foregroundColor(.forgeMuted)
                                    .padding(.top, 48)
                                Text("No sessions")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.forgeInk)
                                Text("Your scheduled sessions will appear here.")
                                    .font(.system(size: 13))
                                    .foregroundColor(.forgeInk3)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 100)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(displayedSessions) { session in
                                    SessionCard(session: session, isSelected: selected?.id == session.id) {
                                        selected = session
                                        showDetail = true
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100)
                        }
                    }
                    .padding(.top, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("Notifications", isPresented: $showNotifications) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("No new notifications.")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 8) {
                        EpisignLogo(size: 28)
                        Text("Episign")
                            .font(.system(size: 17, weight: .bold))
                            .kerning(-0.4)
                            .foregroundColor(.forgeInk)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNotifications = true
                    } label: {
                        Image(systemName: "bell")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.forgeInk)
                    }
                }
            }
            .sheet(isPresented: $showDetail, onDismiss: {
                Task { await loadSessions() }
            }) {
                if let session = selected {
                    CourseDetailView(session: session, onSigned: {
                        Task { await loadSessions() }
                    })
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
            }
        }
        .onAppear {
            filter = initialFilter == .schedule ? .upcoming : .today
            Task { await loadSessions() }
        }
    }

    private func loadSessions() async {
        guard let login = auth.user?.login else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let db = try await SupabaseService.shared.getStudentSessions(login: login)
            sessions = db.map { $0.toCourseSession() }
        } catch {
            loadingError = error.localizedDescription
        }
    }
}

// MARK: - Session Card

struct SessionCard: View {
    let session: CourseSession
    var isSelected: Bool = false
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 8) {
                    // Code badge
                    Text(session.code)
                        .font(.system(size: 11, weight: .bold))
                        .kerning(0.4)
                        .foregroundColor(.forgeBrand)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.forgeTint)
                        .cornerRadius(6)

                    if session.isLive {
                        ForgePill(text: "LIVE NOW", tone: .live, dot: true)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.forgeMuted)
                }

                Text(session.name)
                    .font(.system(size: 17, weight: .semibold))
                    .kerning(-0.3)
                    .foregroundColor(.forgeInk)
                    .padding(.top, 10)

                Text(session.teacher)
                    .font(.system(size: 13))
                    .foregroundColor(.forgeInk3)
                    .padding(.top, 2)

                HStack(spacing: 16) {
                    MetaChip(icon: "clock", label: session.timeRange)
                    MetaChip(icon: "mappin", label: session.room)
                }
                .padding(.top, 12)

                if session.isLive {
                    ForgeButton(
                        title: "Sign attendance · Émargement",
                        systemIcon: "qrcode",
                        action: onTap
                    )
                    .padding(.top, 14)
                }
            }
            .padding(18)
            .background(Color.forgeCard)
            .cornerRadius(20)
            .shadow(
                color: isSelected
                    ? Color.forgeBrand.opacity(0.14)
                    : Color(hex: "0A1B2E").opacity(0.03),
                radius: isSelected ? 28 : 2, y: isSelected ? 8 : 1
            )
            .shadow(
                color: isSelected
                    ? Color.forgeBrand.opacity(0)
                    : Color(hex: "0A1B2E").opacity(0.05),
                radius: 14, y: 4
            )
            .overlay(
                isSelected
                    ? RoundedRectangle(cornerRadius: 20).stroke(Color.forgeBrand.opacity(0.55), lineWidth: 1.5)
                    : nil
            )
        }
        .buttonStyle(.plain)
    }
}

struct MetaChip: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
            Text(label)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(.forgeInk3)
    }
}

struct FilterChip: View {
    let label: String
    var active: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(active ? Color.forgeBrand : Color.forgeCard)
                .foregroundColor(active ? .white : .forgeInk3)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.04), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
}
