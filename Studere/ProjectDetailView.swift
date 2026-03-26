import SwiftUI
import SwiftData

// MARK: - ProjectDetailView
// Shows the scaffolded study as an ordered list of components.
//
// KEY CHANGES from v1:
//   - No manual "add block" or "add edge" as primary actions
//   - Components shown in methodological sequence (template order)
//   - Each component shows its pre-wired connections
//   - Completion progress is the main indicator
//   - Tapping opens the inspector inline or as a sheet

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: ResearchProject
    
    @State private var selectedNode: ResearchNode?
    @State private var showingSetup = false
    
    var body: some View {
        Group {
            if project.isScaffolded {
                scaffoldedView
            } else {
                setupPrompt
            }
        }
        .navigationTitle(project.title)
        .sheet(item: $selectedNode) { node in
            NodeInspectorSheet(node: node)
        }
        .sheet(isPresented: $showingSetup) {
            StudySetupView(project: project) {
                showingSetup = false
            }
        }
    }
    
    // MARK: - Setup Prompt (for projects without a scaffold yet)
    
    private var setupPrompt: some View {
        ContentUnavailableView {
            Label("Choose a Study Design", systemImage: "rectangle.3.group")
        } description: {
            Text("Select a study design type to get started. The app will set up all required components and connections.")
        } actions: {
            Button {
                showingSetup = true
            } label: {
                Label("Set Up Study", systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Scaffolded Study View
    
    private var scaffoldedView: some View {
        List {
            // Study overview
            Section {
                overviewCard
            }
            
            // Component list in template order
            Section {
                ForEach(project.scaffoldedNodes) { node in
                    ComponentRowView(node: node)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedNode = node }
                }
            } header: {
                HStack {
                    Text("Study Components")
                    Spacer()
                    let progress = project.completionProgress
                    Text("\(progress.filled)/\(progress.total) fields")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Text("Tap any component to answer its inspector questions. All connections have been set up based on your \(project.designType?.displayName ?? "study") design.")
                    .font(.caption)
            }
            
            // Connections (read-only, for reference)
            if !project.edges.isEmpty {
                Section("Connections") {
                    ForEach(project.edges) { edge in
                        ConnectionRowView(edge: edge)
                    }
                }
            }
        }
    }
    
    // MARK: - Overview Card
    
    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if let designType = project.designType {
                    Image(systemName: designType.iconName)
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    TextField("Study Title", text: $project.title)
                        .font(.title3.weight(.semibold))
                        .textFieldStyle(.plain)
                    
                    Text(project.designType?.displayName ?? "Unknown Design")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Progress bar
            let progress = project.completionProgress
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(
                    value: progress.total > 0 ? Double(progress.filled) / Double(progress.total) : 0
                )
                .tint(progressColor(filled: progress.filled, total: progress.total))
                
                HStack {
                    Text(progressLabel(filled: progress.filled, total: progress.total))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(project.status.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.accentColor.opacity(0.12))
                        )
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helpers
    
    private func progressColor(filled: Int, total: Int) -> Color {
        guard total > 0 else { return .gray }
        let ratio = Double(filled) / Double(total)
        if ratio >= 1.0 { return .green }
        if ratio >= 0.5 { return .accentColor }
        return .orange
    }
    
    private func progressLabel(filled: Int, total: Int) -> String {
        guard total > 0 else { return "No fields to fill" }
        if filled == total { return "All required fields completed" }
        return "\(filled) of \(total) required fields completed"
    }
}
