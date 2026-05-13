import SwiftUI

struct AttendanceView: View {
    @EnvironmentObject var auth: AuthService
    @State private var isLoading = true
    @State private var records: [AttendanceRecord] = []
    @State private var summary: AttendanceSummary? = nil

    @State private var periodIndex = 0
    let periods = ["Semester", "Month", "Week"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.forgeBg.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                } else if let summary = summary {
                    attendanceContent(summary: summary)
                } else {
                    emptyState
                }
            }
            .navigationTitle("My attendance")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            // Attendance history RPC not yet available — show empty state
            isLoading = false
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 44))
                .foregroundColor(.forgeMuted)
            Text("No attendance data")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.forgeInk)
            Text("Your attendance history will appear here once sessions are recorded.")
                .font(.system(size: 13))
                .foregroundColor(.forgeInk3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
        }
    }

    // MARK: - Data view (shown when real data is available)

    private func attendanceContent(summary: AttendanceSummary) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                SegmentedPicker(options: periods, selected: $periodIndex)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                ForgeCard {
                    HStack(spacing: 18) {
                        DonutChart(percentage: summary.percentage, size: 128)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(summary.presentCount) of \(summary.total) sessions attended, including \(summary.late) late arrivals.")
                                .font(.system(size: 13))
                                .foregroundColor(.forgeInk3)
                                .lineSpacing(3)
                        }
                    }
                    .padding(18)
                }
                .padding(.horizontal, 16)

                ForgeCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("BREAKDOWN")
                            .font(.system(size: 11.5, weight: .semibold))
                            .kerning(0.8)
                            .foregroundColor(.forgeMuted)

                        BreakdownBar(summary: summary)
                            .frame(height: 10)
                            .cornerRadius(5)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            BreakdownCell(label: "Present",     count: summary.attended,          total: summary.total, color: .forgeBrand)
                            BreakdownCell(label: "Late",        count: summary.late,              total: summary.total, color: .forgeWarn)
                            BreakdownCell(label: "Justified",   count: summary.absentJustified,   total: summary.total, color: Color(hex: "4A6A9E"))
                            BreakdownCell(label: "Unjustified", count: summary.absentUnjustified, total: summary.total, color: Color(hex: "B8382F"))
                        }
                    }
                    .padding(18)
                }
                .padding(.horizontal, 16)

                if !records.isEmpty {
                    HStack {
                        Text("Recent sessions")
                            .font(.system(size: 16, weight: .semibold))
                            .kerning(-0.3)
                            .foregroundColor(.forgeInk)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)

                    ForgeCard {
                        VStack(spacing: 0) {
                            ForEach(Array(records.enumerated()), id: \.element.id) { idx, record in
                                AttendanceRow(record: record)
                                if idx < records.count - 1 {
                                    Divider().padding(.leading, 68)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Segmented Picker

struct SegmentedPicker: View {
    let options: [String]
    @Binding var selected: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(options.enumerated()), id: \.offset) { i, label in
                Button {
                    withAnimation(.spring(response: 0.25)) { selected = i }
                } label: {
                    Text(label)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(i == selected ? Color.forgeCard : .clear)
                        .foregroundColor(i == selected ? .forgeInk : .forgeMuted)
                        .cornerRadius(8)
                        .shadow(color: i == selected ? Color.black.opacity(0.08) : .clear, radius: 3, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.forgeChip)
        .cornerRadius(10)
    }
}

// MARK: - Donut Chart

struct DonutChart: View {
    let percentage: Int
    var size: CGFloat = 128
    var strokeWidth: CGFloat = 12

    private var radius: CGFloat { (size - strokeWidth) / 2 }
    private var circumference: CGFloat { 2 * .pi * radius }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.forgeTint, lineWidth: strokeWidth)

            Circle()
                .trim(from: 0, to: CGFloat(percentage) / 100)
                .stroke(
                    Color.forgeBrand,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1), value: percentage)

            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text("\(percentage)")
                        .font(.system(size: 32, weight: .bold))
                        .kerning(-1)
                        .foregroundColor(.forgeInk)
                    Text("%")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.forgeMuted)
                }
                Text("Present")
                    .font(.system(size: 10.5, weight: .semibold))
                    .kerning(0.8)
                    .foregroundColor(.forgeMuted)
                    .textCase(.uppercase)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Breakdown bar

struct BreakdownBar: View {
    let summary: AttendanceSummary

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                barSegment(count: summary.attended,          total: summary.total, color: .forgeBrand,          width: geo.size.width)
                barSegment(count: summary.late,              total: summary.total, color: .forgeWarn,           width: geo.size.width)
                barSegment(count: summary.absentJustified,   total: summary.total, color: Color(hex: "4A6A9E"), width: geo.size.width)
                barSegment(count: summary.absentUnjustified, total: summary.total, color: Color(hex: "B8382F"), width: geo.size.width)
            }
        }
    }

    @ViewBuilder
    private func barSegment(count: Int, total: Int, color: Color, width: CGFloat) -> some View {
        if count > 0 {
            Rectangle()
                .fill(color)
                .frame(width: width * CGFloat(count) / CGFloat(total))
        }
    }
}

// MARK: - Breakdown cell

struct BreakdownCell: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(color).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 12.5))
                    .foregroundColor(.forgeInk3)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(count)")
                        .font(.system(size: 17, weight: .bold))
                        .kerning(-0.3)
                        .foregroundColor(.forgeInk)
                    Text("/ \(total)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.forgeMuted)
                }
            }
        }
    }
}

// MARK: - Attendance Row

struct AttendanceRow: View {
    let record: AttendanceRecord

    var statusBg: Color {
        switch record.status {
        case .attended:          return Color(hex: "E6F4EC")
        case .late:              return Color(hex: "FDEEDC")
        case .absentJustified:   return Color(hex: "E7EDF6")
        case .absentUnjustified: return Color(hex: "FDE6E3")
        }
    }

    var statusFg: Color {
        switch record.status {
        case .attended:          return .forgeSuccess
        case .late:              return .forgeWarn
        case .absentJustified:   return Color(hex: "4A6A9E")
        case .absentUnjustified: return Color(hex: "B8382F")
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.forgeChip)
                    .frame(width: 40, height: 40)
                Text(record.sessionCode.split(separator: "-").first.map(String.init) ?? "")
                    .font(.system(size: 10, weight: .bold))
                    .kerning(0.3)
                    .foregroundColor(.forgeBrandDeep)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(record.sessionName)
                    .font(.system(size: 14, weight: .semibold))
                    .kerning(-0.2)
                    .foregroundColor(.forgeInk)
                    .lineLimit(1)
                Text("\(record.date) · \(record.sessionCode)")
                    .font(.system(size: 12))
                    .foregroundColor(.forgeMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(record.status.label)
                    .font(.system(size: 11, weight: .semibold))
                    .kerning(0.1)
                    .foregroundColor(statusFg)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(statusBg)
                    .cornerRadius(8)

                if let just = record.justification {
                    Text(just)
                        .font(.system(size: 11))
                        .foregroundColor(.forgeMuted)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}
