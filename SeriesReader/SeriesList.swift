import SwiftUI

struct SeriesList: View {
    @State private var localSeries = [Series]()
    
    @State private var alertMessage: String = ""
    @State private var showingAlert: Bool = false
    
    var body: some View {
        List(localSeries) { series in
            NavigationLink(destination: BookList(series: series)) {
                Text(series.title)
            }
        }
        .navigationBarTitle(Text("Series"), displayMode: .inline)
        .navigationBarItems(trailing:
            NavigationLink(destination: RemoteSeriesList()) {
                Text("Download")
            }
        )
        .onAppear(perform: loadLocalSeries)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    func loadLocalSeries() {
        let documentsURL: URL
        do {
            documentsURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        } catch {
            self.alertMessage = error.localizedDescription
            self.showingAlert.toggle()
            return
        }
        
        let seriesRootFolderURL = documentsURL.appendingPathComponent("Series")
        
        if !FileManager.default.fileExists(atPath: seriesRootFolderURL.absoluteString) {
            do {
                try FileManager.default.createDirectory(at: seriesRootFolderURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                self.alertMessage = error.localizedDescription
                self.showingAlert.toggle()
                return
            }
        }

        let seriesFolderNames: [String]
        
        do {
            seriesFolderNames = try FileManager.default.contentsOfDirectory(atPath: seriesRootFolderURL.relativePath)
        } catch {
            self.alertMessage = error.localizedDescription
            self.showingAlert.toggle()
            return
        }

        var series = [Series]()
        
        for (_, seriesFolderName) in seriesFolderNames.sorted().enumerated() {
            if let seriesID =  UUID(uuidString: seriesFolderName) {
                // load series metadata to populate list item
                
                let seriesFolderURL = seriesRootFolderURL.appendingPathComponent(seriesFolderName)
                let metadataURL = seriesFolderURL.appendingPathComponent(".metadata")
                var seriesTitle = "Untitled"
                
                if !FileManager.default.fileExists(atPath: metadataURL.absoluteString) {
                    do {
                        let data = try Data(contentsOf: metadataURL)
                        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
                        seriesTitle = json["title"] as! String
                    } catch {
                        self.alertMessage = error.localizedDescription
                        self.showingAlert.toggle()
                        return
                    }
                }
                
                series.append(Series(id: seriesID, title: seriesTitle))
            }
        }

        DispatchQueue.main.async {
            self.localSeries = series
        }
    }
}

struct SeriesList_Previews: PreviewProvider {
    static var previews: some View {
        SeriesList()
    }
}
