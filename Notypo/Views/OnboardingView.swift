import FoundationModels
import KeyboardShortcuts
import SwiftUI

struct OnboardingView: View {

    @Environment(AccessibilityManager.self) private var accessibilityManager
    @Environment(ProofreadService.self) private var proofreadService

    @State private var currentStep = 0
    var onComplete: () -> Void

    private var steps: [OnboardingStep] {
        var result: [OnboardingStep] = [.welcome]
        if !accessibilityManager.isGranted { result.append(.accessibility) }
        if proofreadService.availability != .available { result.append(.appleIntelligence) }
        result.append(.shortcut)
        result.append(.ready)
        return result
    }

    private var canAdvance: Bool {
        switch steps[currentStep] {
        case .welcome, .shortcut, .ready:
            true
        case .accessibility:
            accessibilityManager.isGranted
        case .appleIntelligence:
            proofreadService.availability == .available
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            stepContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(32)

            footer
                .padding(20)
                .background(.regularMaterial)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
        .frame(width: 480, height: 380)
        .onChange(of: accessibilityManager.isGranted) {
            if accessibilityManager.isGranted, steps[currentStep] == .accessibility {
                advanceAfterDelay()
            }
        }
        .onChange(of: proofreadService.availability) {
            if proofreadService.availability == .available, steps[currentStep] == .appleIntelligence {
                advanceAfterDelay()
            }
        }
    }

    private var stepContent: some View {
        Group {
            switch steps[currentStep] {
            case .welcome:
                welcomeContent
            case .accessibility:
                accessibilityContent
            case .appleIntelligence:
                appleIntelligenceContent
            case .shortcut:
                shortcutContent
            case .ready:
                readyContent
            }
        }
    }

    private var footer: some View {
        HStack {
            stepIndicator

            Spacer()

            if steps[currentStep] == .ready {
                Button("Get Started") {
                    onComplete()
                }
                .buttonStyle(.glassProminent)
            } else {
                Button("Continue") {
                    withAnimation {
                        currentStep = min(currentStep + 1, steps.count - 1)
                    }
                }
                .buttonStyle(.glassProminent)
                .disabled(!canAdvance)
            }
        }
    }

    private func advanceAfterDelay() {
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            withAnimation { currentStep = min(currentStep + 1, steps.count - 1) }
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(steps.indices, id: \.self) { index in
                Circle()
                    .fill(index == currentStep ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private var welcomeContent: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 80, height: 80)

            Text("Welcome to Notypo")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Zero-friction proofreading,\npowered by Apple Intelligence")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var accessibilityContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Accessibility Permission")
                .font(.title)
                .fontWeight(.bold)

            Text("Notypo reads your selected text and types corrections back. This requires Accessibility access.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            if accessibilityManager.isGranted {
                Label("Permission Granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            } else {
                Button("Grant Access") {
                    accessibilityManager.requestPermission()
                }
                .controlSize(.large)
            }
        }
    }

    private var appleIntelligenceContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "apple.intelligence")
                .font(.system(size: 48))
                .foregroundStyle(
                    .linearGradient(
                        colors: [.blue, .purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Apple Intelligence")
                .font(.title)
                .fontWeight(.bold)

            switch proofreadService.availability {
            case .available:
                Label("Model Ready", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            case .unavailable(.appleIntelligenceNotEnabled):
                Text("Apple Intelligence needs to be enabled to use on-device proofreading.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)

                Button("Open Settings") {
                    proofreadService.openAppleIntelligenceSettings()
                }
                .controlSize(.large)
            case .unavailable(.modelNotReady):
                Text("The proofreading model is still downloading. This may take a few minutes.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)

                ProgressView()
                    .controlSize(.large)
            case .unavailable(.deviceNotEligible):
                Text("This device does not support Apple Intelligence. Notypo requires a compatible Mac.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            case .unavailable:
                Text("Apple Intelligence is currently unavailable.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }
        }
    }

    private var shortcutContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "keyboard")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Your Shortcut")
                .font(.title)
                .fontWeight(.bold)

            Text("Select text anywhere, then press your shortcut to proofread instantly.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            KeyboardShortcuts.Recorder("", name: .proofread)
                .padding(.top, 8)
        }
    }

    private var readyContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("You're All Set!")
                .font(.title)
                .fontWeight(.bold)

            Text("Select some text and press your shortcut to try it out. Notypo lives in your menu bar. Look for the icon up top.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
    }
}

private enum OnboardingStep: Equatable {
    case welcome
    case accessibility
    case appleIntelligence
    case shortcut
    case ready
}
