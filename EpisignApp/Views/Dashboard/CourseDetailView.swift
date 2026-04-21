import SwiftUI

struct CourseDetailView: View {
    let session: CourseSession
    @State private var showCheckIn = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.forgeBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Blue gradient header
                    ZStack(alignment: .topLeading) {
                        LinearGradient(
                            colors: [Color.forgeBrandDeep, Color.forgeBrand],
                            startPoint: .top, endPoint: .bottom
                        )

                        Circle()
                            .fill(RadialGradient(
                                colors: [Color.white.opacity(0.18), .clear],
                                center: .center, startRadius: 0, endRadius: 110
                            ))
                            .frame(width: 220, height: 220)
                            .offset(x: UIScreen.main.bounds.width - 60, y: -60)

                        VStack(alignment: .leading, spacing: 0) {
                            // Nav buttons
                            HStack {
                                Button(action: { dismiss() }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.18))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.18))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.top, 16)

                            if session.isLive {
                                ForgePill(text: "LIVE · STARTED 14 MIN AGO", tone: .live, dot: true)
                                    .padding(.top, 20)
                            }

                            Text(session.code)
                                .font(.system(size: 11.5, weight: .bold))
                                .kerning(1)
                                .foregroundColor(.white.opacity(0.75))
                                .padding(.top, session.isLive ? 16 : 36)

                            Text(session.name)
                                .font(.system(size: 26, weight: .bold))
                                .kerning(-0.6)
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .padding(.top, 4)

                            Text(session.teacher)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.85))
                                .padding(.top, 6)
                                .padding(.bottom, 22)
                        }
                        .padding(.horizontal, 20)
                    }
                    .cornerRadius(0)

                    // Metadata card
                    ForgeCard {
                        VStack(spacing: 0) {
                            ForEach(metadataRows, id: \.key) { row in
                                MetadataRow(item: row)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)

                    // Today's topic
                    ForgeCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("TODAY'S TOPIC")
                                .font(.system(size: 11.5, weight: .semibold))
                                .kerning(0.3)
                                .foregroundColor(.forgeMuted)
                            Text("Dynamic programming · complexity analysis and memoization patterns.")
                                .font(.system(size: 14.5))
                                .foregroundColor(.forgeInk2)
                                .lineSpacing(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)

                    Spacer(minLength: 120)
                }
            }

            // Sticky CTA
            VStack(spacing: 10) {
                ForgeButton(
                    title: "Attendance · Émargement",
                    systemIcon: "qrcode",
                    action: { showCheckIn = true }
                )
                Text("Closes automatically at **09:15**")
                    .font(.system(size: 11.5))
                    .foregroundColor(.forgeMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 16)
            .background(
                LinearGradient(
                    colors: [Color.forgeBg.opacity(0), Color.forgeBg],
                    startPoint: .top, endPoint: .bottom
                )
            )
        }
        .fullScreenCover(isPresented: $showCheckIn) {
            CheckInFlowView(session: session)
        }
    }

    private var metadataRows: [MetadataItem] {
        [
            MetadataItem(key: "Date",     value: session.dateLabel, icon: "calendar"),
            MetadataItem(key: "Time",     value: session.timeRange, icon: "clock"),
            MetadataItem(key: "Room",     value: "\(session.room) · Building B", icon: "building.2"),
            MetadataItem(key: "Duration", value: "90 minutes",    icon: "timer"),
            MetadataItem(key: "Enrolled", value: "42 students",   icon: "person.2"),
        ]
    }
}

struct MetadataItem {
    let key: String
    let value: String
    let icon: String
}

struct MetadataRow: View {
    let item: MetadataItem

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.forgeTint)
                    .frame(width: 32, height: 32)
                Image(systemName: item.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.forgeBrand)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(item.key.uppercased())
                    .font(.system(size: 11.5, weight: .semibold))
                    .kerning(0.3)
                    .foregroundColor(.forgeMuted)
                Text(item.value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.forgeInk)
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 18)
        Divider().padding(.leading, 62).opacity(0.6)
    }
}
