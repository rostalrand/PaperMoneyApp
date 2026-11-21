# Running the iOS Simulator on Windows (Without a Mac)

## The Reality of Apple iOS Simulator
Apple's native Xcode IDE and its iOS Simulator runtime (`CoreSimulator`) run exclusively on Apple's macOS operating system. Apple does not release a Windows version of the Xcode simulator.

However, because our **GitHub Actions cloud pipeline** (`macos-latest` Apple Silicon runners) compiles your real SwiftUI code into native iOS Simulator binaries, you can run and view the actual simulator from Windows using the solutions below.

---

## Option 1: Cloud-Streamed Real iOS Simulator (Appetize.io)
> **Recommended & Fastest**: Takes 2 minutes. Free tier available (no credit card required).

Appetize.io runs genuine Apple iOS Simulators on real Apple cloud infrastructure and streams the interactive screen to your desktop. **This is the actual compiled native Swift binary running on Apple's CoreSimulator engine, not a web mockup.**

### Quick Steps:
1. **Download the Compiled Simulator App**:
   - Go to your GitHub Actions build: [GitHub Actions Run 44871291053](https://github.com/rostalrand/PaperMoneyApp/actions/runs/44871291053)
   - Under **Artifacts**, click **`PaperMoneyApp-Simulator-Build`** to download the zip file (2.19 MB).
2. **Upload to Appetize**:
   - Open [https://appetize.io/upload](https://appetize.io/upload) in your browser.
   - Drag and drop `PaperMoneyApp-Simulator.app.zip`.
   - Select your preferred device (e.g. **iPhone 15 Pro** or **iPhone 16** with iOS 17/18).
3. **Interact with the Simulator**:
   - Tap **"Play"** to launch.
   - You can click to tap, scroll through stocks, execute paper trades, test limit orders, trigger price alerts, and inspect the 1-time cold launch ad overlay.

---

## Option 2: Run Directly on a Physical iPhone (Apple TestFlight)
If you own an iPhone or iPad, you do not need a Mac or a simulator:
1. Enroll in the Apple Developer Program ($99/year).
2. Our GitHub Actions pipeline compiles and pushes signed builds directly to **Apple TestFlight**.
3. Install the **TestFlight** app from the App Store on your iPhone.
4. Tap **Install** to test the native app directly on physical Apple hardware.

---

## Option 3: Remote Cloud Mac (Full Native Xcode & Simulator)
If you want the complete, authentic Xcode IDE experience with the desktop Apple Simulator window:
1. Rent an on-demand cloud Mac via [MacinCloud](https://www.macincloud.com/) (approx. $1/hour or pay-as-you-go).
2. Connect from Windows using standard **Windows Remote Desktop** (`mstsc.exe`).
3. Inside the remote Mac desktop:
   - Open Xcode.
   - Clone `git@github.com:rostalrand/PaperMoneyApp.git`.
   - Select an iPhone simulator and press `Cmd + R` to run.
