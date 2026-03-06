import Observation

@MainActor
@Observable
final class OnboardingViewModel {

    enum Step: Equatable {
        case welcome
        case accessibility
        case appleIntelligence
        case shortcut
        case ready
    }

    let steps: [Step]
    var currentStep = 0

    var step: Step { steps[currentStep] }
    var isLastStep: Bool { step == .ready }

    var canAdvance: Bool {
        switch step {
        case .welcome, .shortcut, .ready:
            true
        case .accessibility:
            AccessibilityManager.shared.isGranted
        case .appleIntelligence:
            ProofreadService.shared.availability == .available
        }
    }

    init() {
        var result: [Step] = [.welcome]
        if !AccessibilityManager.shared.isGranted { result.append(.accessibility) }
        if ProofreadService.shared.availability != .available { result.append(.appleIntelligence) }
        result.append(.shortcut)
        result.append(.ready)
        steps = result
    }

    func advance() {
        guard currentStep < steps.count - 1 else { return }
        currentStep += 1
    }

    func advanceAfterDelay() {
        Task {
            try? await Task.sleep(for: .seconds(2))
            advance()
        }
    }
}
