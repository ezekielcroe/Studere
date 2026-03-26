import SwiftUI
import SwiftData

// MARK: - ContentView
// Main navigation. When a new project is created, it opens
// in the setup flow. Existing scaffolded projects open directly.

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ResearchProject.modifiedAt, order: .reverse) private var projects: [ResearchProject]
    
    @State private var selectedProject: ResearchProject?
    @State private var showingSetup = false
    @State private var pendingProject: ResearchProject?
    
    var body: some View {
        NavigationSplitView {
            ProjectListView(
                projects: projects,
                selectedProject: $selectedProject,
                onAddProject: createProject,
                onDeleteProjects: deleteProjects
            )
        } detail: {
            if let project = selectedProject {
                ProjectDetailView(project: project)
            } else {
                ContentUnavailableView(
                    "No Study Selected",
                    systemImage: "rectangle.3.group",
                    description: Text("Select a study from the sidebar or create a new one.")
                )
            }
        }
        .sheet(isPresented: $showingSetup) {
            if let project = pendingProject {
                StudySetupView(project: project) {
                    showingSetup = false
                    selectedProject = project
                }
            }
        }
    }
    
    private func createProject() {
        let project = ResearchProject()
        modelContext.insert(project)
        pendingProject = project
        showingSetup = true
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
