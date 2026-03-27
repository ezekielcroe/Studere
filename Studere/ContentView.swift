import SwiftUI
import SwiftData

// MARK: - ContentView
// Main navigation. Keyboard shortcuts:
//   ⌘N  — New study
//   ⌘S  — Explicit save with visual confirmation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ResearchProject.modifiedAt, order: .reverse) private var projects: [ResearchProject]
    
    @State private var selectedProject: ResearchProject?
    @State private var showingSetup = false
    @State private var pendingProject: ResearchProject?
    @State private var showingSavedBadge = false
    
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
                ProjectDetailView(
                    project: project,
                    onSave: performSave
                )
            } else {
                ContentUnavailableView(
                    "No Study Selected",
                    systemImage: "rectangle.3.group",
                    description: Text("Select a study from the sidebar or create a new one.")
                )
            }
        }
        .overlay(alignment: .topTrailing) {
            SaveBadgeView(isVisible: showingSavedBadge)
                .padding(.top, 6)
                .padding(.trailing, 16)
        }
        .sheet(isPresented: $showingSetup) {
            if let project = pendingProject {
                StudySetupView(project: project) {
                    showingSetup = false
                    selectedProject = project
                }
            }
        }
        // Hidden button to capture ⌘S globally
        .background {
            Button("", action: performSave)
                .keyboardShortcut("s", modifiers: .command)
                .hidden()
        }
        // Hidden button to capture ⌘N globally
        .background {
            Button("", action: createProject)
                .keyboardShortcut("n", modifiers: .command)
                .hidden()
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
    
    private func performSave() {
        do {
            try modelContext.save()
            withAnimation(.easeIn(duration: 0.15)) {
                showingSavedBadge = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showingSavedBadge = false
                }
            }
        } catch {
            print("Save failed: \(error)")
        }
    }
}

// MARK: - SaveBadgeView
// A small confirmation badge that briefly appears after ⌘S.

struct SaveBadgeView: View {
    let isVisible: Bool
    
    var body: some View {
        Group {
            if isVisible {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                    Text("Saved")
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.12))
                        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
