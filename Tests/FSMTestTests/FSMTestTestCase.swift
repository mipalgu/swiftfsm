import Foundation
import XCTest

class FSMTestTestCase: XCTestCase {

    var readableName: String {
#if os(macOS)
        self.name
            .dropFirst(2)
            .dropLast()
            .components(separatedBy: .whitespacesAndNewlines)
            .joined(separator: "_")
#else
        self.name.components(separatedBy: .whitespacesAndNewlines).joined(separator: "_")
#endif
    }

    var originalPath: String!

    var testFolder: URL!

    override func setUpWithError() throws {
        let fm = FileManager.default
        originalPath = fm.currentDirectoryPath
        let filePath = URL(fileURLWithPath: #filePath, isDirectory: false)
        testFolder = filePath
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("kripke_structures", isDirectory: true)
            .appendingPathComponent(readableName, isDirectory: true)
        _ = try? fm.removeItem(atPath: testFolder.path)
        try fm.createDirectory(at: testFolder, withIntermediateDirectories: true)
        fm.changeCurrentDirectoryPath(testFolder.path)
    }

    override func tearDownWithError() throws {
        let fm = FileManager.default
        fm.changeCurrentDirectoryPath(originalPath)
    }

}
