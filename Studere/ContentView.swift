import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ResearchProject.modifiedAt, order: .reverse) private var projects: [ResearchProject]
    
    @State private var selectedProject: ResearchProject?
    @State private var showingSetup = false
    
    // Safely track the selection after a database insert
    @State private var pendingSelection: ResearchProject?
    
    var body: some View {
        NavigationSplitView {
            ProjectListView(
                projects: projects,
                selectedProject: $selectedProject,
                onAddProject: {
                    showingSetup = true
                },
                onDeleteProjects: deleteProjects
            )
        } detail: {
            ZStack {
                if let project = selectedProject {
                    ProjectDetailView(project: project)
                        .id(project.persistentModelID)
                } else {
                    ContentUnavailableView(
                        "No Study Selected",
                        systemImage: "rectangle.3.group",
                        description: Text("Select a study from the sidebar or create a new one.")
                    )
                }
            }
        }
        .sheet(isPresented: $showingSetup) {
            StudySetupView { title, template, choices in
                showingSetup = false
                
                // 1. Create and insert the project on the MAIN context safely
                let newProject = ResearchProject(title: title)
                modelContext.insert(newProject)
                
                // 2. Build the scaffold inside the main context
                ScaffoldBuilder.buildScaffold(
                    from: template,
                    choices: choices,
                    for: newProject,
                    in: modelContext
                )
                
                newProject.status = .draft
                
                // 3. Force the context to save immediately, then queue the selection
                do {
                    try modelContext.save()
                    pendingSelection = newProject
                } catch {
                    print("CRITICAL SAVE ERROR: \(error.localizedDescription)")
                }
            }
        }
        .focusedSceneValue(\.createNewProjectAction, {
            showingSetup = true
        })
        .onChange(of: projects) { _, newProjects in
            if let pending = pendingSelection,
               newProjects.contains(where: { $0.persistentModelID == pending.persistentModelID }) {
                withAnimation { selectedProject = pending }
                pendingSelection = nil
            }
        }
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
