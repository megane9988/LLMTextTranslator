import Cocoa
import AVFoundation
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: ApplicationCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App launched")
        
        Task { @MainActor in
            coordinator = ApplicationCoordinator()
            coordinator?.startApplication()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        Task { @MainActor in
            coordinator?.cleanup()
        }
    }
}
