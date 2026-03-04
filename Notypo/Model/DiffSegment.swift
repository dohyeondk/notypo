import Foundation
import SwiftUI

enum DiffSegment: Equatable {
    case unchanged(String)
    case deleted(String)
    case added(String)

    static func wordDiff(original: String, corrected: String) -> [DiffSegment] {
        let oldWords = original.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        let newWords = corrected.split(separator: " ", omittingEmptySubsequences: false).map(String.init)

        let m = oldWords.count
        let n = newWords.count

        // LCS table
        var dp = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)
        for i in 1...max(m, 1) where i <= m {
            for j in 1...max(n, 1) where j <= n {
                if oldWords[i - 1] == newWords[j - 1] {
                    dp[i][j] = dp[i - 1][j - 1] + 1
                } else {
                    dp[i][j] = max(dp[i - 1][j], dp[i][j - 1])
                }
            }
        }

        // Backtrack
        var segments: [DiffSegment] = []
        var i = m, j = n
        while i > 0 || j > 0 {
            if i > 0 && j > 0 && oldWords[i - 1] == newWords[j - 1] {
                segments.append(.unchanged(oldWords[i - 1]))
                i -= 1; j -= 1
            } else if j > 0 && (i == 0 || dp[i][j - 1] >= dp[i - 1][j]) {
                segments.append(.added(newWords[j - 1]))
                j -= 1
            } else {
                segments.append(.deleted(oldWords[i - 1]))
                i -= 1
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
