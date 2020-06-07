import Foundation

func getMetatdata(at: URL) throws -> [String: Any] {
    let metadataURL: URL = at.appendingPathComponent(".metadata")
    
    if !fileExists(at: metadataURL) {
        let data: Data = try Data(contentsOf: metadataURL)
        return try JSONSerialization.jsonObject(with: data) as! [String: Any]
    }
    
    return [String: Any]()
}

func getSeries() throws -> [Series] {
    let seriesDirectoryNames: [String] = try getSeriesDirectoryNames()
    var series:[Series] = [Series]()
    
    for (_, seriesDirectoryName) in seriesDirectoryNames.sorted().enumerated() {
        if let seriesID: UUID = UUID(uuidString: seriesDirectoryName) {
            let seriesURL: URL = try getSeriesURL(directoryName: seriesDirectoryName)
            let metadata: [String: Any] = try getMetatdata(at: seriesURL)
            var title: String
            
            if !metadata.isEmpty {
                title = metadata["title"] as! String
            } else {
                title = seriesDirectoryName
            }
            
            series.append(Series(id: seriesID, title: title))
        }
    }
    
    return series
}

func getSeriesDirectoryNames() throws -> [String] {
    let seriesRootURL: URL = try getSeriesRootURL()
    
    if !fileExists(at: seriesRootURL) {
        try createDirectory(at: seriesRootURL)
    }

    return try contentsOfDirectory(at: seriesRootURL)
}

func getSeriesRootURL() throws -> URL {
    let documentsURL: URL = try getDocumentsURL()
    return documentsURL.appendingPathComponent("Series")
}

func getSeriesURL(directoryName: String) throws -> URL {
    return try getSeriesRootURL().appendingPathComponent(directoryName)
}
