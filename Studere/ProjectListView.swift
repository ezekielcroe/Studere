import SwiftUI

// MARK: - ProjectListView
// Sidebar showing all research projects with their design type and progress.
struct ProjectListView: View {
    let projects: [ResearchProject]
    @Binding var selectedProject: ResearchProject?
    var onAddProject: () -> Void
    var onDeleteProjects: (IndexSet) -> Void
    
    var body: some View {
        List(selection: $selectedProject) {
            ForEach(projects) { project in
                NavigationLink(value: project) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.title)
                            .font(.headline)
                            .lineLimit(1)
                        
                        HStack(spacing: 8) {
                            if let designType = project.designType {
                                Label(designType.displayName, systemImage: designType.iconName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Label("Not set up", systemImage: "wrench")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            
                            Spacer()
                            
                            if project.isScaffolded {
                                let progress = project.completionProgress
                                if progress.total > 0 {
                                    Text("\(Int(Double(progress.filled) / Double(progress.total) * 100))%")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(progress.filled == progress.total ? .green : .secondary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .onDelete(perform: onDeleteProjects)
        }
        // FIX: Adds native Return/Enter key and double-click support
        .contextMenu(forSelectionType: ResearchProject.self) { selection in
            if !selection.isEmpty {
                Button("Delete", role: .destructive) {
                    // Map the selected objects back to their indices for the existing onDelete closure
                    let indices = selection.compactMap { proj in
                        projects.firstIndex(where: { $0.id == proj.id })
                    }
                    onDeleteProjects(IndexSet(indices))
                }
            }
        }
        .navigationTitle("Studies")
        .toolbar {
            ToolbarItem { // Removed placement: .primaryAction
                Button(action: onAddProject) {
                    Label("New Study", systemImage: "plus")
                }
            }
        }
    }
}
