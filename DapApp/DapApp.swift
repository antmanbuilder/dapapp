import SwiftUI

@main
struct DapApp: App {
    @StateObject private var root = AppRootModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(root.history)
                .environmentObject(root.flow)
        }
    }
}

/// Single place to wire `DapHistoryStore` into `DapFlowViewModel` so stats and ads flags stay consistent.
final class AppRootModel: ObservableObject {
    let history: DapHistoryStore
    let flow: DapFlowViewModel

    init() {
        let h = DapHistoryStore()
        history = h
        flow = DapFlowViewModel(history: h)
    }
}
