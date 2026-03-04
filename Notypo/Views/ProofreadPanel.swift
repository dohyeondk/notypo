import AppKit
import SwiftUI

struct ProofreadPanel: View {

    @Bindable var session: ProofreadSession

    private var retryButton: some View {
        Button {
            Task { await session.run() }
        } label: {
            Label("Retry", systemImage: "arrow.clockwise")
        }
        .keyboardShortcut("r", modifiers: .command)
        .buttonStyle(.glass)
        .opacity(session.isProcessing ? 0 : 1)
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
        .buttonStyle(.glass)
    }

    private var copyButton: some View {
        Button {
            if case .succeeded(let corrected) = session.phase {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(corrected, forType: .string)
            }
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }
        .keyboardShortcut("c", modifiers: .command)
        .buttonStyle(.glass)
        .disabled(session.isProcessing)
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
        .disabled(session.isProcessing)
    }

    private var toolbar: some View {
        HStack {
            ZStack(alignment: .leading) {
                retryButton
                if session.isProcessing { processingLabel }
            }
            Spacer()
            discardButton
            copyButton
            applyButton
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(session.attributedText)
                .font(.title3)
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
    ProofreadPanel(session: session)
}
