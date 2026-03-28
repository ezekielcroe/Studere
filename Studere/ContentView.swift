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
                onDuplicateProject: { project in
                    duplicateProject(project)
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
                
                let newProject = ResearchProject(title: title)
                modelContext.insert(newProject)
                
                ScaffoldBuilder.buildScaffold(
                    from: template,
                    choices: choices,
                    for: newProject,
                    in: modelContext
                )
                
                newProject.status = .draft
                
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
        .focusedSceneValue(\.duplicateProjectAction, {
            if let project = selectedProject {
                duplicateProject(project)
            }
        })
        .onChange(of: projects) { _, newProjects in
            if let pending = pendingSelection,
               newProjects.contains(where: { $0.persistentModelID == pending.persistentModelID }) {
                withAnimation { selectedProject = pending }
                pendingSelection = nil
            }
        }
    }
    
    // MARK: - Actions
    
    private func duplicateProject(_ project: ResearchProject) {
        let duplicate = ProjectDuplicator.duplicate(project, in: modelContext)
        pendingSelection = duplicate
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
