# Notypo

A macOS menu bar app that proofreads your text using Apple Intelligence. Select text anywhere, hit a shortcut, and typos are fixed in place with a floating diff panel showing what changed.

## Features

- **Global keyboard shortcut** — trigger proofreading from any app (default: `⌃Space`, customizable)
- **In-place correction** — selected text is replaced with the corrected version automatically
- **Floating diff panel** — shows word-level changes with strikethrough for removals and green for additions
- **Tone guide** — optionally steer corrections toward a specific tone (e.g. casual, formal)
- **Auto-dismiss** — correction panel disappears after a configurable duration, or on any keypress

## Requirements

- macOS 26.0+
- Apple Intelligence enabled
- Accessibility permission granted

## Tech Stack

- Swift 6 / SwiftUI
- [FoundationModels](https://developer.apple.com/documentation/foundationmodels) (on-device LLM)
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) for global hotkey registration

## Getting Started

1. Clone the repo and open `Notypo.xcodeproj`
2. Build and run (requires Xcode 26+)
3. Grant Accessibility permission when prompted
4. Ensure Apple Intelligence is enabled in System Settings
5. Select text in any app and press `⌃Space`

## Releasing

Push a version tag to trigger the release pipeline:

```bash
git tag v0.3.0
git push origin v0.3.0
```

GitHub Actions will build, sign, notarize, package a DMG, and create a GitHub Release automatically.

## License

MIT
