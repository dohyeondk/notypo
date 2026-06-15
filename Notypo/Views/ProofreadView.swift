import AppKit
import SwiftUI

struct ProofreadView: View {

    @Bindable var session: ProofreadSession

    private var tintColor: Color {
        if session.phase == .failed { return .red.opacity(0.3) }
        if session.isPerfect { return .green.opacity(0.3) }
        return .clear
    }

    private var toolbar: some View {
        HStack(spacing: 20) {
            DiscardButton {
                session.onDiscard?()
            }

            Group {
                RetryButton {
                    Task { await session.run() }
                }

                Spacer()

                CopyButton(string: session.corrected)

                ApplyButton {
                    session.onApply?(session.corrected)
                }
            }
            .opacity(session.isProcessing ? 0 : 1)
        }
        .overlay(alignment: .trailing) {
            if session.isProcessing {
                ProcessingLabel()
            }
        }
        .buttonStyle(.plain)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextView(string: session.attributedString)

            toolbar
                .padding(12)
                .background(.regularMaterial)
        }
        .background(tintColor)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
        .frame(width: 520)
        .task {
            try? await Task.sleep(for: .seconds(0.5))
            await session.run()
        }
    }
}

private struct TextView: View {
    let string: AttributedString

    var body: some View {
        Text(string)
            .font(.title2)
            .lineLimit(20)
            .fixedSize(horizontal: false, vertical: true)
            .padding(12)
    }
}

private struct DiscardButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Label("Discard", systemImage: "escape")
        }
        .keyboardShortcut(.escape, modifiers: [])
    }
}

private struct RetryButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Label("Retry", systemImage: "arrow.clockwise")
        }
        .keyboardShortcut("r", modifiers: .command)
    }
}

private struct CopyButton: View {
    let string: String?

    @State private var showCopied = false

    var body: some View {
        Button {
            if let string {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(string, forType: .string)
                showCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showCopied = false
                }
            }
        } label: {
            Label(
                "Copy",
                systemImage: showCopied ? "checkmark" : "doc.on.doc"
            )
            .contentTransition(.symbolEffect(.replace))
        }
        .keyboardShortcut("c", modifiers: .command)
    }
}

private struct ApplyButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Label("Apply", systemImage: "return")
        }
        .keyboardShortcut(.return, modifiers: [])
        .buttonStyle(.glassProminent)
    }
}

private struct ProcessingLabel: View {
    var body: some View {
        Label {
            Text("Proofreading...")
        } icon: {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.small)
        }
    }
}

#Preview {
    let session = ProofreadSession(
        originalText: "Id nostrud voluptate voluptate. Voluptate aliqua eiusmod dolor minim ut. " +
            "Velit tempor incididunt ea esse incididunt incididunt cillum id commodo duis et."
    )
    ProofreadView(session: session)
}

#Preview {
    CopyButton(string: "Esse qui aute duis irure nostrud.")
}
