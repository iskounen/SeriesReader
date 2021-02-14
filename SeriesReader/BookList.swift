import SwiftUI

struct BookList: View {
    @State private var localBooks = [Book]()
    
    @State private var alertMessage: String = ""
    @State private var showingAlert: Bool = false
    
    var series: Series
    
    var body: some View {
        List(localBooks) { book in
            NavigationLink(destination: PageCarousel(series: self.series, book: book)) {
                Text(String(book.number))
            }
        }
        .navigationBarTitle(Text(series.title))
        .onAppear(perform: loadBooks)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func loadBooks() {
        let seriesFolderName = self.series.id.uuidString

        let documentsURL: URL
        do {
            documentsURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        } catch {
            self.alertMessage = error.localizedDescription
            self.showingAlert.toggle()
            return
        }

        let seriesRootFolderURL = documentsURL.appendingPathComponent("Series")
        let seriesFolderURL = seriesRootFolderURL.appendingPathComponent(seriesFolderName)

        let bookFolderNames: [String]
        do {
            bookFolderNames = try FileManager.default.contentsOfDirectory(atPath: seriesFolderURL.relativePath)
        } catch {
            self.alertMessage = error.localizedDescription
            self.showingAlert.toggle()
            return
        }

        var books = [Book]()

        for (_, bookFolderName) in bookFolderNames.enumerated() {
            if let bookID =  UUID(uuidString: bookFolderName) {
                // load book metadata to populate list item
                
                let bookFolderURL = seriesFolderURL.appendingPathComponent(bookFolderName)
                let metadataURL = bookFolderURL.appendingPathComponent(".metadata")
                var bookNumber = 0
                
                if !FileManager.default.fileExists(atPath: metadataURL.absoluteString) {
                    do {
                        let data = try Data(contentsOf: metadataURL)
                        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
                        bookNumber = json["number"] as! Int
                    } catch {
                        self.alertMessage = error.localizedDescription
                        self.showingAlert.toggle()
                        return
                    }
                }
                books.append(Book(id: bookID, number: bookNumber))
            }
        }
        
        books.sort {
            $0.number < $1.number
        }

        DispatchQueue.main.async {
            self.localBooks = books
        }
    }
}

struct BookList_Previews: PreviewProvider {
    static var previews: some View {
        BookList(series: Series(id: UUID(), title: "Test"))
    }
}
