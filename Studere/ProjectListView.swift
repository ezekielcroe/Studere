import SwiftUI

// MARK: - ProjectListView
// Sidebar showing all research projects with their design type and progress.
//
// Actions:
//   New Study       — creates a blank project and opens setup
//   Duplicate Study — deep copies the selected project
//   Delete Study    — removes the project and all its data

struct ProjectListView: View {
    let projects: [ResearchProject]
    @Binding var selectedProject: ResearchProject?
    var onAddProject: () -> Void
    var onDuplicateProject: ((ResearchProject) -> Void)?
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
        .contextMenu(forSelectionType: ResearchProject.self) { selection in
            if let project = selection.first {
                Button {
                    onDuplicateProject?(project)
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                
                Divider()
                
                Button("Delete", role: .destructive) {
                    let indices = selection.compactMap { proj in
                        projects.firstIndex(where: { $0.id == proj.id })
                    }
                    onDeleteProjects(IndexSet(indices))
                }
            }
        }
        .navigationTitle("Studies")
        .toolbar {
            ToolbarItemGroup {
                Button(action: onAddProject) {
                    Label("New Study", systemImage: "plus")
                }
                .help("Create a new study (⌘N)")
                
                Button {
                    if let project = selectedProject {
                        onDuplicateProject?(project)
                    }
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                .help("Duplicate selected study (⌘D)")
                .disabled(selectedProject == nil)
            }
        }
    }
}
