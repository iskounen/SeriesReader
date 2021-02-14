import SwiftUI

struct RemoteSeriesList: View {
    @State private var remoteSeries: [Series] = [Series]()
    
    @State private var alertMessage: String = ""
    @State private var showingAlert: Bool = false
    
    var body: some View {
        List(remoteSeries) { series in
            NavigationLink(destination: RemoteBookList(series: series)) {
                Text(series.title)
            }
        }
        .navigationBarTitle(Text("Available Series"))
        .onAppear(perform: loadRemoteSeries)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    func loadRemoteSeries() {
        let address = "http://192.168.0.171:3000/series.json"
        
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
                    let decodedResponse = try JSONDecoder().decode([Series].self, from: data)
                    DispatchQueue.main.async {
                        self.remoteSeries = decodedResponse
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
}

struct RemoteSeriesList_Previews: PreviewProvider {
    static var previews: some View {
        RemoteSeriesList()
    }
}
