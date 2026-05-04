import SwiftUI
import AppKit

@main
struct CursedApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 600, minHeight: 400)
                .background(WindowAspectLock(ratio: NSSize(width: 3, height: 2)))
        }
        .defaultSize(width: 1200, height: 800)
    }
}

private struct WindowAspectLock: NSViewRepresentable {
    let ratio: NSSize

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { [weak view] in
            view?.window?.contentAspectRatio = ratio
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { [weak nsView] in
            nsView?.window?.contentAspectRatio = ratio
        }
    }
}
