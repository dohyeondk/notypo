import AppKit
import SwiftUI

struct ProofreadView: View {

    @Bindable var session: ProofreadSession
    @State private var showCopied = false

    private var retryButton: some View {
        Button {
            Task { await session.run() }
        } label: {
            Label("Retry", systemImage: "arrow.clockwise")
        }
        .keyboardShortcut("r", modifiers: .command)
    }

    private var processingLabel: some View {
        Label {
            Text("Proofreading...")
        } icon: {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.small)
        }
    }

    private var discardButton: some View {
        Button {
            session.onDiscard?()
        } label: {
            Label("Discard", systemImage: "escape")
        }
        .keyboardShortcut(.escape, modifiers: [])
    }

    private var copyButton: some View {
        Button {
            if case .succeeded(let corrected) = session.phase {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(corrected, forType: .string)
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

    private var applyButton: some View {
        Button {
            if case .succeeded(let corrected) = session.phase {
                session.onApply?(corrected)
            }
        } label: {
            Label("Apply", systemImage: "return")
        }
        .keyboardShortcut(.return, modifiers: [])
        .buttonStyle(.glassProminent)
    }

    private var toolbar: some View {
        HStack(spacing: 20) {
            discardButton
                .opacity(session.isProcessing ? 0 : 1)

            retryButton
                .opacity(session.isProcessing ? 0 : 1)

            Spacer()
            
            copyButton
            applyButton
        }
        .overlay(alignment: .leading) {
            if session.isProcessing { processingLabel }
        }
        .disabled(session.isProcessing)
        .buttonStyle(.plain)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(session.attributedText)
                .font(.title2)
                .lineLimit(20)
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)

            toolbar
                .padding(12)
                .background(.regularMaterial)
        }
        .background(session.isPerfect ? .green.opacity(0.3) : .clear)
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

#Preview {
    let session = ProofreadSession(originalText: "Id nostrud voluptate voluptate. Voluptate aliqua eiusmod dolor minim ut. Velit tempor incididunt ea esse incididunt incididunt cillum id commodo duis et.")
    ProofreadView(session: session)
}
