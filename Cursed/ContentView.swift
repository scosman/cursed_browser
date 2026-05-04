import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var appState = AppState()
    @State private var chromeHeight: CGFloat = 0
    @StateObject private var windowLock = WindowLockController(canvasRatio: 3.0 / 2.0)

    var body: some View {
        VStack(spacing: 0) {
            ChromeBar(appState: appState)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: ChromeHeightKey.self, value: geo.size.height)
                    }
                )
            CanvasView(appState: appState)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onPreferenceChange(ChromeHeightKey.self) { newValue in
            chromeHeight = newValue
            windowLock.update(chromeHeight: newValue, window: keyWindow())
        }
        .onAppear {
            windowLock.update(chromeHeight: chromeHeight, window: keyWindow())
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { appState.currentError != nil },
                set: { if !$0 { appState.currentError = nil } }
            ),
            presenting: appState.currentError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.errorDescription ?? "An unknown error occurred.")
        }
    }

    private func keyWindow() -> NSWindow? {
        return NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first
    }
}

private struct ChromeHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

@MainActor
final class WindowLockController: ObservableObject {
    let canvasRatio: CGFloat
    private var chromeHeight: CGFloat = 0
    private weak var window: NSWindow?
    private var observers: [NSObjectProtocol] = []

    init(canvasRatio: CGFloat) {
        self.canvasRatio = canvasRatio
    }

    deinit {
        for token in observers {
            NotificationCenter.default.removeObserver(token)
        }
    }

    func update(chromeHeight: CGFloat, window: NSWindow?) {
        self.chromeHeight = chromeHeight
        if let window = window, window !== self.window {
            self.window = window
            attachObservers(to: window)
        }
        // Retry shortly if window not yet available.
        if window == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                guard let self = self, self.window == nil else { return }
                if let w = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first {
                    self.window = w
                    self.attachObservers(to: w)
                    self.applyLock()
                }
            }
            return
        }
        applyLock()
    }

    private func attachObservers(to window: NSWindow) {
        for token in observers {
            NotificationCenter.default.removeObserver(token)
        }
        observers.removeAll()
        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: NSWindow.didResizeNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.applyLock() }
        })
        observers.append(center.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.applyLock() }
        })
    }

    private func applyLock() {
        guard let window = window, chromeHeight > 0 else { return }
        let contentW = window.contentLayoutRect.width
        guard contentW > 0 else { return }
        let canvasH = contentW / canvasRatio
        let totalContentH = canvasH + chromeHeight
        window.contentAspectRatio = NSSize(width: contentW, height: totalContentH)
        let currentContentH = window.contentLayoutRect.height
        if abs(currentContentH - totalContentH) > 0.5 {
            let titleH = max(0, window.frame.height - currentContentH)
            var frame = window.frame
            let newFrameH = totalContentH + titleH
            frame.origin.y += frame.height - newFrameH
            frame.size.height = newFrameH
            window.setFrame(frame, display: true, animate: false)
        }
    }
}
