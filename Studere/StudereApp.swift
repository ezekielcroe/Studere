import SwiftUI
import SwiftData

// MARK: - Studere App Entry Point
// Multi-platform SwiftUI app targeting macOS 14+ and iPadOS 17+.
// Uses SwiftData for local-first persistence of the research design DAG.

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
