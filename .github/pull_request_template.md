## Description
Briefly describe what changes this PR introduces and why they are necessary.

Fixes #(issue number)

## Type of Change
- [ ] 🚀 New feature (non-breaking change which adds functionality)
- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ⚡ Performance optimization
- [ ] 💅 UI/UX improvement
- [ ] 📑 Documentation / Release notes
- [ ] 🧪 Tests / CI configuration

## Core Verification Checklist
- [ ] **Zero-Login Preserved**: No mandatory account registration, passwords, or emails introduced.
- [ ] **iCloud Key-Value Storage**: Changes sync correctly through `NSUbiquitousKeyValueStore` with local fallback.
- [ ] **Quota Protection**: Transactions and snapshots remain within the 1 MB KVS limit.
- [ ] **Clean Monetization**: Strictly 1-time cold launch AdMob overlay; NO sticky banners or trading interruptions.
- [ ] **Automated Tests**: All 29 unit tests in `PortfolioTests.swift` pass.
- [ ] **Simulator Tested**: Tested in `simulator.html` or macOS Xcode iOS simulator.

## Screenshots / Video (if visual change)
| Before | After |
| :--- | :--- |
| <!-- image --> | <!-- image --> |
