import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: ApplicationCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App launched")
        startApplication()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("App terminating")
        cleanupApplication()
    }
    
    // MARK: - アプリケーション管理
    private func startApplication() {
        Task { @MainActor in
            coordinator = ApplicationCoordinator()
            coordinator?.startApplication()
        }
    }
    
    private func cleanupApplication() {
        Task { @MainActor in
            coordinator?.cleanup()
            coordinator = nil
        }
    }
}
