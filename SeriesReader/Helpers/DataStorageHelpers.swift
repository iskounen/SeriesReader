import Foundation

func contentsOfDirectory(at: URL) throws -> [String] {
    try FileManager.default.contentsOfDirectory(atPath: at.relativePath)
}

func createDirectory(at: URL) throws {
    try FileManager.default.createDirectory(at: at, withIntermediateDirectories: true, attributes: nil)
}

func fileExists(at: URL) -> Bool {
    FileManager.default.fileExists(atPath: at.absoluteString)
}

func getDocumentsURL() throws -> URL {
    try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
}
