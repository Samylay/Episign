import SwiftUI

// FORGE design system — matches the HTML prototype palette exactly
extension Color {
    static let forgeInk       = Color(hex: "0A1B2E")
    static let forgeInk2      = Color(hex: "1C2E4A")
    static let forgeInk3      = Color(hex: "4A5D7A")
    static let forgeMuted     = Color(hex: "8896AB")
    static let forgeBg        = Color(hex: "F4F6FA")
    static let forgeChip      = Color(hex: "EEF3FB")
    static let forgeTint      = Color(hex: "E8F0FC")
    static let forgeBrand     = Color(hex: "1E4FD6")
    static let forgeBrandDeep = Color(hex: "153FB0")
    static let forgeBrandSoft = Color(hex: "3E74E8")
    static let forgeBrandInk  = Color(hex: "0B2A7A")
    static let forgeAccent    = Color(hex: "5B8DF0")
    static let forgeSuccess   = Color(hex: "1E8F5F")
    static let forgeWarn      = Color(hex: "C8782B")
    static let forgeCard      = Color.white
    static let forgeHairline  = Color(hex: "0A1B2E").opacity(0.08)

    init(hex: String) {
        var str = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: str).scanHexInt64(&value)
        let r, g, b, a: UInt64
        switch str.count {
        case 6: (a, r, g, b) = (255, value >> 16, value >> 8 & 0xFF, value & 0xFF)
        case 8: (a, r, g, b) = (value >> 24, value >> 16 & 0xFF, value >> 8 & 0xFF, value & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Pill component

enum PillTone {
    case brand, neutral, live, warn
}

struct ForgePill: View {
    let text: String
    var tone: PillTone = .brand
    var dot: Bool = false

    var bg: Color {
        switch tone {
        case .brand:   return .forgeTint
        case .neutral: return Color(hex: "EEF1F6")
        case .live:    return Color(hex: "E6F4EC")
        case .warn:    return Color(hex: "FDEEDC")
        }
    }

    var fg: Color {
        switch tone {
        case .brand:   return .forgeBrandDeep
        case .neutral: return .forgeInk2
        case .live:    return .forgeSuccess
        case .warn:    return .forgeWarn
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            if dot {
                Circle()
                    .fill(fg)
                    .frame(width: 6, height: 6)
                    .shadow(color: fg.opacity(0.35), radius: 3)
            }
            Text(text)
                .font(.system(size: 11.5, weight: .semibold))
                .letterSpacing(0.1)
        }
        .padding(.horizontal, 9)
        .frame(height: 22)
        .background(bg)
        .foregroundColor(fg)
        .clipShape(Capsule())
    }
}

// MARK: - Primary button

struct ForgeButton: View {
    let title: String
    var secondary: Bool = false
    var icon: Image? = nil
    var systemIcon: String? = nil
    var action: () -> Void = {}

    var bg: Color { secondary ? .white : .forgeBrand }
    var fg: Color { secondary ? .forgeInk : .white }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let sys = systemIcon {
                    Image(systemName: sys).font(.system(size: 16, weight: .semibold))
                } else if let img = icon {
                    img.resizable().frame(width: 20, height: 20)
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .kerning(-0.2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(bg)
            .foregroundColor(fg)
            .cornerRadius(20)
            .shadow(
                color: secondary
                    ? Color.black.opacity(0.04)
                    : Color.forgeBrand.opacity(0.28),
                radius: secondary ? 2 : 14,
                y: secondary ? 1 : 4
            )
            .overlay(
                secondary
                    ? RoundedRectangle(cornerRadius: 20).stroke(Color.black.opacity(0.1), lineWidth: 1)
                    : nil
            )
        }
    }
}

// MARK: - Card container

struct ForgeCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder _ content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .background(Color.forgeCard)
            .cornerRadius(20)
            .shadow(color: Color(hex: "0A1B2E").opacity(0.03), radius: 2, y: 1)
            .shadow(color: Color(hex: "0A1B2E").opacity(0.05), radius: 14, y: 4)
    }
}

// MARK: - Step dots (check-in flow)

struct StepDots: View {
    let active: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i <= active ? Color.forgeBrand : Color.white.opacity(0.25))
                    .frame(width: i == active ? 24 : 12, height: 4)
                    .animation(.spring(response: 0.3), value: active)
            }
        }
    }
}

struct LightStepDots: View {
    let active: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i <= active ? Color.forgeBrand : Color.forgeHairline)
                    .frame(width: i == active ? 24 : 12, height: 4)
                    .animation(.spring(response: 0.3), value: active)
            }
        }
    }
}

// MARK: - Font helper (letterSpacing via kerning)

extension View {
    func letterSpacing(_ value: CGFloat) -> some View {
        self.kerning(value)
    }
}
