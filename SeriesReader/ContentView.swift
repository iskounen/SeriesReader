import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            SeriesList(fetcher: getSeries)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
