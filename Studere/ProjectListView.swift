import SwiftUI

// MARK: - ProjectListView
// Sidebar list of all research projects. Phase 1 test UI.

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
                        HStack {
                            Text(project.status.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(project.nodes.count) blocks")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .onDelete(perform: onDeleteProjects)
        }
        .navigationTitle("Studies")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: onAddProject) {
                    Label("New Study", systemImage: "plus")
                }
            }
        }
    }
}
