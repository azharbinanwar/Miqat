# Contributing to Miqat

Thank you for taking the time to contribute. Here is everything you need to get started.

---

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/your-username/Miqat.git`
3. Open `Miqat.xcodeproj` in Xcode 15+
4. Run on your Mac — no additional setup needed

---

## Branching

- `main` — stable, always buildable
- Create a feature branch from `main`: `git checkout -b feat/your-feature`
- Use `fix/` for bug fixes, `feat/` for new features, `chore/` for cleanup

---

## Code Style

- Swift 5.9+, SwiftUI + AppKit
- Follow the existing architecture: **Model → Repository → ViewModel → View**
- ViewModels use `@Observable` — no `ObservableObject`
- Keep logic out of Views — Views are display only
- No third-party UI frameworks — AppKit/SwiftUI only
- No comments explaining *what* code does — only *why* if non-obvious

---

## Commit Messages

Use conventional commits:

```
feat: add qibla compass screen
fix: tracker not seeding missed prayers after wake from sleep
chore: remove debug print statements
docs: update README screenshots
```

---

## Pull Requests

- Keep PRs focused — one feature or fix per PR
- Include a short description of what changed and why
- Screenshots or a short screen recording for any UI change
- Make sure the app builds and runs before opening a PR

---

## Reporting Bugs

Open an issue and include:
- macOS version
- Steps to reproduce
- What you expected vs what happened
- Screenshot or screen recording if relevant

---

## Feature Requests

Open an issue with the `enhancement` label. Explain the use case, not just the feature. If it fits the scope of the app (prayer times, tracker, notifications) it will be considered.

---

## What's Out of Scope

- Qibla compass — planned for later
- Quran reading or Islamic content beyond prayer times
- Any backend, user accounts, or cloud sync
- App Store distribution (free and open source only)

---

## License

By contributing you agree that your contributions will be licensed under the [MIT License](LICENSE).
