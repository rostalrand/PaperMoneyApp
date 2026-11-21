# Contributing to Paper Money iOS

Thank you for contributing to **Paper Money**! This guide outlines the development standards, branching model, and code review process.

---

## 1. Branching Strategy

We follow a GitFlow-inspired branching strategy:

- **`main`**: Production releases only. Every commit must be stable, tested, and ready for App Store submission.
- **`develop`**: The primary integration branch where all completed features merge.
- **`feature/<feature-name>`**: Branch off `develop` for new capabilities (e.g., `feature/options-paper-trading`).
- **`bugfix/<bug-name>`**: Branch off `develop` to resolve issues (e.g., `bugfix/candlestick-zoom`).
- **`release/vX.Y.Z`**: Branch off `develop` for release hardening and metadata updates before merging to `main`.

---

## 2. Commit Message Conventions

We enforce [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short description>
```

### Common Types:
- `feat`: A new feature or user-facing capability (e.g. `feat(charts): add technical indicator overlays`)
- `fix`: A bug fix (e.g. `fix(orders): prevent negative share count on sell`)
- `perf`: Performance improvement (e.g. `perf(canvas): optimize candlestick rendering loop`)
- `refactor`: Code reorganization with no behavior changes
- `test`: Adding or updating test cases
- `docs`: Documentation or release note updates
- `chore`: Tooling, build system, or dependency updates

---

## 3. Core Architecture Tenets

When modifying the codebase, always preserve these core requirements:

1. **Zero-Login Frictionless Philosophy**:
   - Never require user registration, email, or passwords.
   - All persistence must use native `NSUbiquitousKeyValueStore` with local fallback.
2. **Quota Protection**:
   - Keep total serialized KVS payload under 1 MB. Transactions and snapshots must remain bounded.
3. **Clean Monetization**:
   - The app strictly features **one** Google AdMob App Open overlay on cold launch.
   - Never introduce banner ads, sticky bottom ads, or trade flow interruptions.
4. **Offline Resilience**:
   - Always provide offline/weekend fallbacks (e.g. 24/7 micro-tick simulator) so users can trade anytime.

---

## 4. Local Testing & Verification

Before submitting a Pull Request:

1. **Run Automated Unit Tests**:
   - Open `PaperMoneyApp.xcodeproj` in Xcode on macOS.
   - Press `Cmd + U` to run all 29 XCTest cases in `PortfolioTests.swift`.
   - Ensure 100% pass rate.
2. **Browser Simulator Check**:
   - Open `simulator.html` in your browser.
   - Verify UI rendering, charts, order matching, and settings modal.
3. **Pre-Commit Checks**:
   - Ensure no merge markers or private keys are committed (`.githooks/pre-commit` runs automatically).

---

## 5. Submitting a Pull Request

1. Push your branch to GitHub:
   ```bash
   git push origin feature/my-new-feature
   ```
2. Open a Pull Request targeting the `develop` branch.
3. Fill out the PR template checklist completely.
4. Ensure all GitHub Actions CI checks (`.github/workflows/ios-ci.yml`) pass.
