import SwiftUI
import SwiftData

// MARK: - Focused Values
// Scene-scoped actions that menu commands can invoke.
extension FocusedValues {
    @Entry var createNewProjectAction: (() -> Void)?
    @Entry var duplicateProjectAction: (() -> Void)?
}

// MARK: - App Entry Point
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
        .commands {
            StudereCommands()
        }
    }
}

// MARK: - Menu Commands
struct StudereCommands: Commands {
    @FocusedValue(\.createNewProjectAction) private var createNewProject
    @FocusedValue(\.duplicateProjectAction) private var duplicateProject
    
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Study") {
                createNewProject?()
            }
            .keyboardShortcut("n", modifiers: .command)
            .disabled(createNewProject == nil)
            
            Button("Duplicate Study") {
                duplicateProject?()
            }
            .keyboardShortcut("d", modifiers: .command)
            .disabled(duplicateProject == nil)
        }
    }
}
