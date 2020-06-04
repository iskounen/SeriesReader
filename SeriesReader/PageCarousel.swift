import SwiftUI

struct PageCarousel: View {
    @State private var localPages = [Page(id: 0, name: "", image: UIImage())]
    
    @State private var alertMessage: String = ""
    @State private var showingAlert: Bool = false
    
    var series: Series
    var book: Book
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(localPages) { page in
                    Image(uiImage: page.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .rotation3DEffect(Angle(degrees: 180), axis: (x: CGFloat(0), y: CGFloat(10), z: CGFloat(0)))
                }
            }
        }
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear(perform: loadPages)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func loadPages() {
        let documentsURL: URL
        do {
            documentsURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        } catch {
            self.alertMessage = error.localizedDescription
            self.showingAlert.toggle()
            return
        }
        
        let seriesRoot: URL = documentsURL.appendingPathComponent("Series")
        let seriesFolder: URL = seriesRoot.appendingPathComponent(self.series.id.uuidString)
        let bookFolder: URL = seriesFolder.appendingPathComponent(String(self.book.id.uuidString))
        
        let items: [String]
        
        do {
            items = try FileManager.default.contentsOfDirectory(atPath: bookFolder.relativePath)
        } catch {
            self.alertMessage = error.localizedDescription
            self.showingAlert.toggle()
            return
        }

        var pages = [Page]()
        
        for (index, item) in items.sorted().enumerated() {
            if (item == ".DS_Store" || item == ".metadata") {
                continue
            }
            
            let pageURL: URL = bookFolder.appendingPathComponent(item)
            
            let imageData: Data
            
            do {
                imageData = try Data(contentsOf: pageURL)
            } catch {
                self.alertMessage = error.localizedDescription
                self.showingAlert.toggle()
                return
            }
            pages.append(Page(id: index, name: item, image: UIImage(data: imageData)!))
        }
        
        pages.sort { Int($0.name.split(separator: ".")[0])! < Int($1.name.split(separator: ".")[0])! }

        DispatchQueue.main.async {
            self.localPages = pages
        }
    }
}

struct PageCarousel_Previews: PreviewProvider {
    static var previews: some View {
        PageCarousel(series: Series(id: UUID(), title: "Preview"), book: Book(id: UUID(), number: 0))
    }
}
