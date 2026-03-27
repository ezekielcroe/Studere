import SwiftUI
import SwiftData

// MARK: - Focused Values
// Step 1: Define the scene-scoped values using the modern @Entry macro.
// This allows the active window to communicate its capabilities up to the App menu.
extension FocusedValues {
    @Entry var createNewProjectAction: (() -> Void)?
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
        // Step 4: Wire up the commands to the WindowGroup
        .commands {
            StudereCommands()
        }
    }
}

// MARK: - Menu Commands
// Step 3: Consume the focused values to build the actual menu items.
struct StudereCommands: Commands {
    // FIX: Always read from @FocusedValue here, which automatically
    // captures the scene-scoped value we will publish from ContentView.
    @FocusedValue(\.createNewProjectAction) private var createNewProject
    
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Study") {
                createNewProject?()
            }
            .keyboardShortcut("n", modifiers: .command)
            // Automatically grays out the menu item if no window is active
            .disabled(createNewProject == nil)
        }
    }
}
