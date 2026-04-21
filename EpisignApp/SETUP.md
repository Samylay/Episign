# Episign iOS App — Setup

## Xcode Project Creation

1. Open Xcode → **File → New → Project**
2. Choose **iOS → App**
3. Set:
   - Product Name: `Episign`
   - Bundle ID: `fr.epita.episign`
   - Interface: SwiftUI
   - Language: Swift
4. Delete the generated `ContentView.swift` and `<AppName>App.swift`
5. Drag the entire `EpisignApp/` folder into the Xcode project navigator
6. When prompted: **Add to target: Episign** ✓, **Copy items if needed** ✓

## Required Capabilities (Xcode Signing & Capabilities)

1. **Near Field Communication Tag Reading**  
   → Signing & Capabilities → + → NFC Tag Reading  
   → Select `TAG` under "NFCReaderUsageDescription"

2. **Face ID** is handled via `LocalAuthentication` — no extra entitlement needed

## Replace Info.plist

If Xcode generated its own `Info.plist`, merge in the keys from the provided `Info.plist`:
- `NSFaceIDUsageDescription`
- `NFCReaderUsageDescription`
- `CFBundleURLTypes` (for the `episign://` callback scheme)

## ForgeID OAuth Credentials

The app ships with the **public test client**:
```
Client ID: 125070
```

For production, email `tickets@forge.epita.fr` to request a production client with:
- App name: `Episign`
- Redirect URI: `episign://callback`
- Required scopes: `openid profile email epita`

## Minimum Deployment Target

iOS 16.0+ (uses `NavigationStack`, `async/await`, SwiftUI charts)

## App Screens

| Screen | File |
|--------|------|
| Sign In (ForgeID OIDC) | `Views/Auth/AuthView.swift` |
| Session Dashboard | `Views/Dashboard/DashboardView.swift` |
| Course Detail | `Views/Dashboard/CourseDetailView.swift` |
| Check-in Flow (3 steps) | `Views/CheckIn/` |
| Step 1 · Face ID | `Views/CheckIn/FaceIDStepView.swift` |
| Step 2 · Teacher NFC | `Views/CheckIn/TeacherScanStepView.swift` |
| Step 3 · Confirmation | `Views/CheckIn/StudentConfirmStepView.swift` |
| Attendance Analytics | `Views/Analytics/AttendanceView.swift` |
| Profile | `Views/Profile/ProfileView.swift` |

## Architecture

```
AuthService          — OIDC PKCE flow via ASWebAuthenticationSession + Keychain
NFCService           — CoreNFC TAG reader (ISO14443 / ISO15693)
CheckInViewModel     — coordinates the 3-step check-in flow
```
