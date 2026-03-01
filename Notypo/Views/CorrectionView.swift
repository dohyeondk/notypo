import SwiftUI

struct CorrectionView: View {
    let segments: [DiffSegment]

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "text.badge.checkmark")
                .foregroundStyle(.secondary)

            Text(diffAttributedString)
                .lineLimit(6)
        }
        .padding(12)
        .fixedSize(horizontal: false, vertical: true)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
    }

    private var diffAttributedString: AttributedString {
        var result = AttributedString()
        for segment in segments {
            switch segment {
            case .unchanged(let word):
                result.append(AttributedString(word + " "))
            case .deleted(let word):
                var attr = AttributedString(word + " ")
                attr.strikethroughStyle = .single
                attr.foregroundColor = .red
                result.append(attr)
            case .added(let word):
                var attr = AttributedString(word + " ")
                attr.foregroundColor = .green
                result.append(attr)
            }
        }
        return result
    }
}

#Preview {
    CorrectionView(segments: DiffSegment.wordDiff(original: "Hello, word!", corrected: "Hello, world!"))
}
