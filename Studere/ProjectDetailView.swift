import SwiftUI
import SwiftData

// MARK: - ProjectDetailView
// Shows the scaffolded study as an ordered list of components.
//

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: ResearchProject
    
    @State private var selectedNode: ResearchNode?
    @State private var showingSetup = false
        
    @State private var showingExporter = false
    @State private var selectedExportFormat: ExportFormat = .markdown
    @State private var documentToExport: StudyExportDocument?
    
    var body: some View {
        Group {
            if project.isScaffolded {
                scaffoldedView
            } else {
                setupPrompt
            }
        }
        .navigationTitle(project.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(ExportFormat.allCases) { format in
                        Button {
                            selectedExportFormat = format
                            documentToExport = StudyExportDocument(project: project, format: format)
                            showingExporter = true
                        } label: {
                            Label("Export as \(format.rawValue)", systemImage: "arrow.down.doc")
                        }
                    }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(!project.isScaffolded) // Can't export an empty setup
            }
        }
        // NEW: System File Exporter Dialog
        .fileExporter(
            isPresented: $showingExporter,
            document: documentToExport,
            contentType: selectedExportFormat.utType,
            defaultFilename: "\(project.title) - Protocol.\(selectedExportFormat.defaultExtension)"
        ) { result in
            switch result {
            case .success(let url):
                print("Successfully exported study to: \(url.path)")
            case .failure(let error):
                print("Export failed: \(error.localizedDescription)")
            }
        }
        .inspector(isPresented: Binding(
            get: { selectedNode != nil },
            set: { isShowing in
                if !isShowing { selectedNode = nil }
            }
        )) {
            if let node = selectedNode {
                NodeInspectorSheet(
                    node: node,
                    allNodes: project.scaffoldedNodes,
                    onNavigate: { nextNode in
                        // Switch the selected node to trigger the new inspector pane
                        selectedNode = nextNode
                    },
                    onSave: {
                        // Safely commit the changes to the database
                        try? modelContext.save()
                    }
                )
                .inspectorColumnWidth(min: 300, ideal: 350, max: 500)
            }
        }
        .sheet(isPresented: $showingSetup) {
            StudySetupView(initialTitle: project.title) { title, template, choices in
                showingSetup = false
                
                // 1. Update the existing project
                project.title = title
                
                // 2. Build the scaffold into this project
                ScaffoldBuilder.buildScaffold(
                    from: template,
                    choices: choices,
                    for: project,
                    in: modelContext
                )
                
                project.status = .draft
                
                // 3. Save the changes
                do {
                    try modelContext.save()
                } catch {
                    print("Error saving scaffolded project: \(error.localizedDescription)")
                }
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
            // CRITICAL FIX: Safely unwrap the optional edges array
            let safeEdges = project.edges ?? []
            if !safeEdges.isEmpty {
                Section("Connections") {
                    ForEach(safeEdges) { edge in
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
