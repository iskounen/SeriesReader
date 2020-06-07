import SwiftUI

struct SeriesList: View {
    var fetcher: () throws -> [Series]
    @State private var localSeries: [Series] = [Series]()
    
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
        .onAppear(perform: loadSeries)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    func loadSeries() {
        let series:[Series]
        
        do {
            series = try fetcher()
        } catch {
            series = [Series]()
            alertMessage = error.localizedDescription
            showingAlert.toggle()
        }

        DispatchQueue.main.async {
            self.localSeries = series
        }
    }
}

struct SeriesList_Previews: PreviewProvider {
    static var previews: some View {
        SeriesList(fetcher: mockSeries)
    }
    
    static func mockSeries() throws -> [Series] {
        var series: [Series] = [Series]()
        
        series.append(Series(id: UUID(), title: "Foo"))
        series.append(Series(id: UUID(), title: "Bar"))
        series.append(Series(id: UUID(), title: "Baz"))
        
        return series
    }
}
