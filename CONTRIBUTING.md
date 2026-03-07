# Contributing

## Setup

1. Requires **macOS 26+**, **Xcode 26+**, and **Apple Intelligence** enabled in System Settings
2. Clone the repo and open `Notypo.xcodeproj` — dependencies resolve automatically
3. Build and run (`Cmd+R`), then grant Accessibility permission when prompted

### Code signing

You don't need signing certificates to develop locally. In the Notypo target's **Signing & Capabilities** tab, set **Signing Certificate** to **Sign to Run Locally**.

## Code Style

Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).

## Submitting Changes

1. Fork the repo and branch from `main`
2. Make sure the project builds and tests pass (`Cmd+U`)
3. Open a PR with a clear description of what changed and why

For bugs, include steps to reproduce. For features, describe the use case.

## License

Contributions are licensed under [MIT](LICENSE).
