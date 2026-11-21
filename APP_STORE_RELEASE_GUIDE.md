# Apple App Store Release & Deployment Guide

This guide provides the exact step-by-step instructions for submitting **Paper Money** to the Apple App Store, including Xcode archiving, code signing, App Store Connect metadata, privacy declarations, and AdMob production cutover.

---

## 1. App Store Metadata & Identifiers

| Field | Configuration / Value |
| :--- | :--- |
| **App Name** | `Paper Money - Stock Trading Simulator` |
| **Subtitle** | `Virtual stock market practice` (30 chars max) |
| **Bundle Identifier** | `com.antigravity.papermoney` |
| **Primary Category** | `Finance` |
| **Secondary Category** | `Education` |
| **Age Rating** | `4+` (No gambling, no adult content, zero real money transactions) |
| **Price** | Free (with 1-time launch sponsorship overlay) |
| **Target OS** | iOS 17.0+ (iPhone exclusive) |
| **Version & Build** | `1.0.0` (Build `1`) |

---

## 2. Pre-Release Code Review Checklist

Before creating the release archive, perform these two quick checks:

### A. AdMob Production Cutover
In [AdService.swift](file:///C:/Users/User/.gemini/antigravity/scratch/PaperMoneyApp/PaperMoneyApp/Services/AdService.swift):
```swift
// Change to true when ready for live App Store distribution:
public var isProductionMode: Bool = true

// Insert your production Ad Unit ID from your Google AdMob Dashboard:
public var productionAppOpenAdUnitID: String = "ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY"
```
In [Info.plist](file:///C:/Users/User/.gemini/antigravity/scratch/PaperMoneyApp/PaperMoneyApp/Resources/Info.plist):
Verify `GADApplicationIdentifier` is set to your production AdMob App ID (`ca-app-pub-XXXXXXXXXXXXXXXX~ZZZZZZZZZZ`).

### B. Master App Icon Verification
Verify [appicon-1024.png](file:///C:/Users/User/.gemini/antigravity/scratch/PaperMoneyApp/PaperMoneyApp/Resources/Assets.xcassets/AppIcon.appiconset/appicon-1024.png) is linked in `Contents.json`. Xcode uses this single 1024x1024 PNG asset to automatically compile all home screen, spotlight, and App Store artwork.

---

## 3. Xcode Archiving & Signing Steps

Follow these steps on macOS with Xcode:

1. **Open Project**:
   Double click [PaperMoneyApp.xcodeproj](file:///C:/Users/User/.gemini/antigravity/scratch/PaperMoneyApp/PaperMoneyApp.xcodeproj/project.pbxproj) to open it in Xcode.

2. **Select Team & Signing**:
   - In Xcode's Project Navigator, select **PaperMoneyApp**.
   - Navigate to the **Signing & Capabilities** tab.
   - Under **Signing**, check **Automatically manage signing** and select your active **Apple Developer Team**.
   - Verify the **iCloud** capability shows `iCloud: Key-value storage` enabled with entitlement `com.apple.developer.ubiquity-kvstore-identifier`.

3. **Select Destination**:
   In Xcode's top destination toolbar, select **Any iOS Device (arm64)** (do not select a simulator for archiving).

4. **Run Unit Tests (Recommended)**:
   Press `Cmd + U` to run all 25 automated unit tests in [PortfolioTests.swift](file:///C:/Users/User/.gemini/antigravity/scratch/PaperMoneyApp/PaperMoneyApp/Tests/PortfolioTests.swift). Ensure 100% pass rate.

5. **Create Release Archive**:
   - In Xcode menu, choose **Product > Archive**.
   - Xcode will compile in Release mode (`-O` optimization, dead-code stripping enabled).
   - Once completed, the **Organizer** window opens automatically showing your build.

6. **Validate & Upload**:
   - Click **Validate App** to run automated App Store ingestion checks.
   - Click **Distribute App** > **App Store Connect** > **Upload**.
   - Your build will process on App Store Connect within 5–15 minutes.

---

## 4. App Store Connect Listing Copy

### Description
```
Learn and practice stock market trading with zero risk! Paper Money gives you $100,000 in virtual paper capital to practice buying, selling, and managing investments across top US stocks and ETFs.

KEY FEATURES:
• Zero-Login, Instant Start: No account creation, passwords, or emails required. Open the app and start trading in seconds.
• Private Apple iCloud Sync: Your portfolio, holdings, transactions, and price alerts automatically sync across your Apple devices via your private iCloud storage.
• Real-Time Market Feeds: Live quotes, interactive multi-timeframe charts, and 24/7 offline micro-tick simulation.
• Candlestick & Line Charts: Switch between smooth line charts and high-precision OHLC candlestick bars with real-time price readouts.
• Advanced Order Types: Practice Market Orders, Limit Orders (buy the dip/sell the spike), Stop-Loss protection, and Take-Profit gain locking.
• Custom Price Alerts: Set target price alerts that monitor live ticks and notify you when key levels are breached.
• Market Screener: Instant 1-tap screener pills for Top Gainers, Top Losers, Tech, and ETFs.
• Trader Performance Analytics: Track your cumulative Realized P&L, Win Rate %, and execution counts.
• CSV Statement Export: 1-tap export of your complete trading activity ledger for spreadsheet analysis.
• Ultra-Clean Experience: A single sponsorship overlay on launch. Zero sticky banner ads, zero trade interruptions, and zero subscription paywalls.

NOTE: Paper Money is strictly an educational paper trading simulator. All funds and transactions are virtual. No real money is used or required.
```

### Keywords
`paper trading,stock market,stocks simulator,investing,virtual money,paper money,stock charts,candlestick,trading simulator,portfolio tracker`

### Promotional Text
`Practice stock trading with $100,000 in virtual paper capital. Zero login, iCloud synced, and zero trading interruptions.`

### Support URL & Marketing URL
- Support URL: `https://github.com/` (or your company/product support page)
- Marketing URL: `https://github.com/`

---

## 5. App Store Privacy Questionnaire Answers

When completing the **App Privacy** questionnaire in App Store Connect:

1. **Do you or your third-party partners collect data from this app?**
   - Answer: **No** for user data.
   - For Google AdMob: Check **Diagnostics** / **Device ID** under Third-Party Advertising (standard AdMob ATT disclosure).
2. **Data Tracking**:
   - Declare that identifiers collected by AdMob are not linked to individual user accounts (since Paper Money has zero accounts/login).
3. **Export Compliance**:
   - Already configured in `Info.plist` with `ITSAppUsesNonExemptEncryption = NO` (App Store Connect will bypass encryption questions automatically).

---

## 6. TestFlight Beta Testing

1. Once the build is uploaded, go to **App Store Connect > Apps > Paper Money > TestFlight**.
2. Add internal testers (employees/friends) for instant deployment without Apple review.
3. Add external public beta groups if testing with broader audiences (requires a 24-hour initial TestFlight review).
4. After validation, select the build in the **App Store** tab and click **Submit for Review**!
