import SwiftUI
import Zip

struct RemoteBookList: View {
    @State private var remoteBooks: [Book] = [Book]()
    
    @State private var alertMessage: String = ""
    @State private var showingAlert: Bool = false
    
    var series: Series
    
    var body: some View {
        List(remoteBooks) { book in
            HStack {
                Text(String(book.number))
                Spacer()
                Button(action: {
                    self.downloadRemoteBook(book: book)
                }) {
                    Image(systemName: "icloud.and.arrow.down")
                }
            }
        }
        .navigationBarTitle(Text("Available Books"))
        .onAppear(perform: loadRemoteBooks)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    func loadRemoteBooks() {
        let address = "http://192.168.0.171:3000/series/\(self.series.id.uuidString)/books.json"
        
        guard let url = URL(string: address) else {
            fatalError("Invalid address: \(address)")
        }
        
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                self.alertMessage = error.localizedDescription
                self.showingAlert.toggle()
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                200 == httpResponse.statusCode else {
                    self.alertMessage = response.debugDescription
                    self.showingAlert.toggle()
                    return
            }
            
            if let mimeType = httpResponse.mimeType, mimeType == "application/json", let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode([Book].self, from: data)
                    DispatchQueue.main.async {
                        self.remoteBooks = decodedResponse
                    }
                    return
                } catch {
                    self.alertMessage = error.localizedDescription
                    self.showingAlert.toggle()
                    return
                }
            }

            self.alertMessage = "Unknown error"
            self.showingAlert.toggle()
        }.resume()
    }
    
    func downloadRemoteBook(book: Book) {
        let address = "http://192.168.0.171:3000/series/\(self.series.id.uuidString)/books/\(book.id.uuidString).json"
        
        guard let url = URL(string: address) else {
            fatalError("Invalid address: \(address)")
        }
        
        let request = URLRequest(url: url)
        
        URLSession.shared.downloadTask(with: request) { urlOrNil, responseOrNil, errorOrNil in
            if let error = errorOrNil {
                self.alertMessage = error.localizedDescription
                self.showingAlert.toggle()
                return
            }
            
            guard let httpResponse = responseOrNil as? HTTPURLResponse,
                200 == httpResponse.statusCode else {
                    self.alertMessage = responseOrNil.debugDescription
                    self.showingAlert.toggle()
                    return
            }
            
            guard let downloadedFileURL = urlOrNil else {
                self.alertMessage = "Download error"
                self.showingAlert.toggle()
                return
            }

            do {
                let documentsURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                
                let seriesRootFolderURL = documentsURL.appendingPathComponent("Series")
                let seriesFolderURL = seriesRootFolderURL.appendingPathComponent(self.series.id.uuidString)
                
                if !FileManager.default.fileExists(atPath: seriesFolderURL.absoluteString) {
                    // add a folder for the series
                    
                    do {
                        try FileManager.default.createDirectory(atPath: seriesFolderURL.relativePath, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        self.alertMessage = error.localizedDescription
                        self.showingAlert.toggle()
                        return
                    }
                    
                    // add a file with metadata about the series
                    
                    let metadataURL = seriesFolderURL.appendingPathComponent(".metadata")
                    let metadata = ["title": self.series.title]
                    
                    do {
                        let json = try JSONSerialization.data(withJSONObject:metadata)
                        try json.write(to: metadataURL)
                    } catch {
                        self.alertMessage = error.localizedDescription
                        self.showingAlert.toggle()
                        return
                    }
                }
                
                // move the zip file to the series folder
                
                let unzipDestinationURL = seriesFolderURL.appendingPathComponent("\(book.id.uuidString).zip")
                try FileManager.default.moveItem(at: downloadedFileURL, to: unzipDestinationURL)
                
                do {
                    defer {
                        // delete the zip file

                        do {
                            try FileManager.default.removeItem(at: unzipDestinationURL)
                        } catch {
                            self.alertMessage = error.localizedDescription
                            self.showingAlert.toggle()
                        }
                        
                        // delete the __MACOSX folder that comes with the zip file
                        
                        let resourceForkFolderURL = seriesFolderURL.appendingPathComponent("__MACOSX")
                        
                        do {
                            try FileManager.default.removeItem(at: resourceForkFolderURL)
                        } catch {
                            self.alertMessage = error.localizedDescription
                            self.showingAlert.toggle()
                        }
                    }
                    try Zip.unzipFile(unzipDestinationURL, destination: seriesFolderURL, overwrite: true, password: nil, progress: {(progress) -> () in print(progress)})
                } catch {
                    self.alertMessage = error.localizedDescription
                    self.showingAlert.toggle()
                    return
                }

                // rename the folder to its UUID
                
                let unzippedbookFolderURL = seriesFolderURL.appendingPathComponent(String(book.number))
                print(unzippedbookFolderURL)
                let renamedBookFolderdURL = seriesFolderURL.appendingPathComponent(book.id.uuidString)
                print(renamedBookFolderdURL)
                try FileManager.default.moveItem(at: unzippedbookFolderURL, to: renamedBookFolderdURL)
                
                // add a file with metadata about the book
                
                let metadataURL = renamedBookFolderdURL.appendingPathComponent(".metadata")
                let metadata = ["number": book.number]
                
                do {
                    let json = try JSONSerialization.data(withJSONObject:metadata)
                    try json.write(to: metadataURL)
                } catch {
                    self.alertMessage = error.localizedDescription
                    self.showingAlert.toggle()
                    return
                }
            } catch {
                self.alertMessage = error.localizedDescription
                self.showingAlert.toggle()
                return
            }
        }.resume()
    }
}

struct RemoteBookList_Previews: PreviewProvider {
    static var previews: some View {
        RemoteBookList(series: Series(id: UUID(), title: "Test"))
    }
}
