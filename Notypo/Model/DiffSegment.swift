import Foundation
import SwiftUI

enum DiffSegment: Equatable {
    case unchanged(String)
    case deleted(String)
    case added(String)

    static func wordDiff(original: String, corrected: String) -> [DiffSegment] {
        let oldWords = original.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        let newWords = corrected.split(separator: " ", omittingEmptySubsequences: false).map(String.init)

        let oldCount = oldWords.count
        let newCount = newWords.count

        // LCS table
        var lcs = [[Int]](repeating: [Int](repeating: 0, count: newCount + 1), count: oldCount + 1)
        for row in 1...max(oldCount, 1) where row <= oldCount {
            for col in 1...max(newCount, 1) where col <= newCount {
                if oldWords[row - 1] == newWords[col - 1] {
                    lcs[row][col] = lcs[row - 1][col - 1] + 1
                } else {
                    lcs[row][col] = max(lcs[row - 1][col], lcs[row][col - 1])
                }
            }
        }

        // Backtrack
        var segments: [DiffSegment] = []
        var row = oldCount, col = newCount
        while row > 0 || col > 0 {
            if row > 0 && col > 0 && oldWords[row - 1] == newWords[col - 1] {
                segments.append(.unchanged(oldWords[row - 1]))
                row -= 1; col -= 1
            } else if col > 0 && (row == 0 || lcs[row][col - 1] >= lcs[row - 1][col]) {
                segments.append(.added(newWords[col - 1]))
                col -= 1
            } else {
                segments.append(.deleted(oldWords[row - 1]))
                row -= 1
            }
        }

        return segments.reversed()
    }

    static func attributedString(from segments: [DiffSegment]) -> AttributedString {
        var result = AttributedString()
        for segment in segments {
            switch segment {
            case .unchanged(let word):
                result.append(AttributedString(word + " "))
            case .deleted(let word):
                var attr = AttributedString(word + " ")
                attr.strikethroughStyle = .single
                attr.foregroundColor = .pink
                result.append(attr)
            case .added(let word):
                var attr = AttributedString(word + " ")
                attr.foregroundColor = .mint
                result.append(attr)
            }
        }
        return result
    }
}
