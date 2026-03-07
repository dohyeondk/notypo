# Notypo

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS 26+](https://img.shields.io/badge/macOS-26%2B-black?logo=apple)](https://developer.apple.com/macos/)

A macOS menu bar app that proofreads your text using Apple Intelligence. Select text anywhere, hit a shortcut, and typos are fixed in place with a floating diff panel showing what changed.

<p align="center">
  <img src="screenshot.png" alt="Notypo proofreading demo" width="600">
</p>

## Download

Grab the latest DMG from [GitHub Releases](https://github.com/dohyeondk/notypo/releases/latest).

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

## Getting Started

### For users

1. Download the DMG from [Releases](https://github.com/dohyeondk/notypo/releases/latest)
2. Drag **Notypo** into Applications
3. Grant Accessibility permission when prompted
4. Ensure Apple Intelligence is enabled in System Settings
5. Select text in any app and press `⌃Space`

### For contributors

See [CONTRIBUTING.md](CONTRIBUTING.md) for dev setup, code style, and PR guidelines.

## Tech Stack

- Swift 6 / SwiftUI
- [FoundationModels](https://developer.apple.com/documentation/foundationmodels) (on-device LLM)
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) for global hotkey registration

## Releasing

Push a version tag to trigger the release pipeline:

```bash
git tag v0.3.0
git push origin v0.3.0
```

GitHub Actions will build, sign, notarize, package a DMG, and create a GitHub Release automatically.

## License

[MIT](LICENSE)
