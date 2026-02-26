import SwiftUI

@main
struct AppRecibosIAApp: App {
    @StateObject private var mlxManager = MLXManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(mlxManager)
                .task {
                    await mlxManager.loadModel()
                }
        }
    }
}
