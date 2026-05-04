import SwiftUI

@main
struct CursedApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 600, minHeight: 400)
        }
        .defaultSize(width: 1200, height: 850)
    }
}
