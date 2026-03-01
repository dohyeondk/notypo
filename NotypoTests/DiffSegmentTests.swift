import Testing
@testable import Notypo

struct DiffSegmentTests {

    @Test func identicalStrings() {
        let segments = DiffSegment.wordDiff(original: "hello world", corrected: "hello world")
        #expect(segments == [.unchanged("hello"), .unchanged("world")])
    }

    @Test func singleTypoFix() {
        let segments = DiffSegment.wordDiff(original: "teh quick fox", corrected: "the quick fox")
        #expect(segments == [.deleted("teh"), .added("the"), .unchanged("quick"), .unchanged("fox")])
    }

    @Test func deletedWord() {
        let segments = DiffSegment.wordDiff(original: "the very quick fox", corrected: "the quick fox")
        #expect(segments == [.unchanged("the"), .deleted("very"), .unchanged("quick"), .unchanged("fox")])
    }

    @Test func addedWord() {
        let segments = DiffSegment.wordDiff(original: "the fox", corrected: "the quick fox")
        #expect(segments == [.unchanged("the"), .added("quick"), .unchanged("fox")])
    }

    @Test func completelyDifferent() {
        let segments = DiffSegment.wordDiff(original: "hello", corrected: "goodbye")
        #expect(segments == [.deleted("hello"), .added("goodbye")])
    }

    @Test func emptyOriginal() {
        let segments = DiffSegment.wordDiff(original: "", corrected: "hello")
        #expect(segments == [.deleted(""), .added("hello")])
    }

    @Test func emptyCorrected() {
        let segments = DiffSegment.wordDiff(original: "hello", corrected: "")
        #expect(segments == [.deleted("hello"), .added("")])
    }

    @Test func bothEmpty() {
        let segments = DiffSegment.wordDiff(original: "", corrected: "")
        #expect(segments == [.unchanged("")])
    }

    @Test func multipleTypos() {
        let segments = DiffSegment.wordDiff(
            original: "I hav a gret idea",
            corrected: "I have a great idea"
        )
        #expect(segments == [
            .unchanged("I"),
            .deleted("hav"),
            .added("have"),
            .unchanged("a"),
            .deleted("gret"),
            .added("great"),
            .unchanged("idea"),
        ])
    }
}
