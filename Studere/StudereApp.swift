import SwiftUI
import SwiftData

@main
struct StudereApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            ResearchProject.self,
            ResearchNode.self,
            ResearchEdge.self
        ])
    }
}
