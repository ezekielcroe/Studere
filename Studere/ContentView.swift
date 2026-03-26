import SwiftUI
import SwiftData

// MARK: - ContentView
// Phase 1 test UI: a simple NavigationSplitView for CRUD operations
// on Projects, Nodes, and Edges. This validates the data model before
// the canvas and full inspector are built.
//
// This will eventually be replaced by the three-panel layout (§4)
// but serves as the Phase 1 deliverable.

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ResearchProject.modifiedAt, order: .reverse) private var projects: [ResearchProject]
    
    @State private var selectedProject: ResearchProject?
    
    var body: some View {
        NavigationSplitView {
            ProjectListView(
                projects: projects,
                selectedProject: $selectedProject,
                onAddProject: addProject,
                onDeleteProjects: deleteProjects
            )
        } detail: {
            if let project = selectedProject {
                ProjectDetailView(project: project)
            } else {
                ContentUnavailableView(
                    "No Study Selected",
                    systemImage: "rectangle.3.group",
                    description: Text("Select a study from the sidebar or create a new one to get started.")
                )
            }
        }
    }
    
    // MARK: - Actions
    
    private func addProject() {
        let project = ResearchProject(title: "New Study")
        modelContext.insert(project)
        selectedProject = project
    }
    
    private func deleteProjects(at offsets: IndexSet) {
        for index in offsets {
            let project = projects[index]
            if selectedProject?.id == project.id {
                selectedProject = nil
            }
            modelContext.delete(project)
        }
    }
}
