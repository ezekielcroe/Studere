import SwiftUI
import SwiftData

// MARK: - ProjectDetailView
// Shows the scaffolded study as an ordered list of components.
//
// Toolbar layout (consolidated):
//   LEFT:   Validate | Add Component | Graph View
//   RIGHT:  Export Raw (menu) | Draft Protocol | (Endorse+Export lives in ProtocolDraftView)
//
// The "Draft Protocol" button is disabled until validation passes.

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: ResearchProject
    
    // MARK: - State
    
    @State private var selectedNode: ResearchNode?
    @State private var showingSetup = false
    @State private var showingDraftView = false
    @State private var showingValidation = false
    @State private var showingAddComponent = false
    @State private var showingGraph = false
    
    // Export state
    @State private var showingExporter = false
    @State private var selectedExportFormat: ExportFormat = .markdown
    @State private var documentToExport: StudyExportDocument?
    
    // Validation state
    @State private var validationReport: ValidationService.Report?
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if project.isScaffolded {
                scaffoldedView
            } else {
                setupPrompt
            }
        }
        .navigationTitle(project.title)
        .toolbar { consolidatedToolbar }
        
        // MARK: - Sheet Modifiers
        
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
        .sheet(isPresented: $showingDraftView) {
            ProtocolDraftView(project: project)
        }
        .sheet(isPresented: $showingValidation) {
            if let report = validationReport {
                ValidationReportView(
                    report: report,
                    onNavigateToNode: { node in
                        selectedNode = node
                    }
                )
            }
        }
        .sheet(isPresented: $showingAddComponent) {
            AddComponentSheet(
                project: project,
                onComponentAdded: { newNode in
                    // Open the inspector for the newly added node
                    selectedNode = newNode
                }
            )
        }
        .sheet(isPresented: $showingGraph) {
            StudyGraphView(
                project: project,
                onSelectNode: { node in
                    selectedNode = node
                }
            )
        }
        // Keyboard shortcut: ⌘⇧V for Validate
        .background {
            Button("", action: runValidation)
                .keyboardShortcut("v", modifiers: [.command, .shift])
                .hidden()
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
                        selectedNode = nextNode
                    },
                    onSave: {
                        try? modelContext.save()
                    },
                    onClose: {
                        selectedNode = nil
                    }
                )
                .inspectorColumnWidth(min: 300, ideal: 350, max: 500)
            }
        }
        .sheet(isPresented: $showingSetup) {
            StudySetupView(initialTitle: project.title) { title, template, choices in
                showingSetup = false
                project.title = title
                ScaffoldBuilder.buildScaffold(
                    from: template,
                    choices: choices,
                    for: project,
                    in: modelContext
                )
                project.status = .draft
                do {
                    try modelContext.save()
                } catch {
                    print("Error saving scaffolded project: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Consolidated Toolbar
    
    @ToolbarContentBuilder
    private var consolidatedToolbar: some ToolbarContent {
        
        // LEFT GROUP: Design & review actions
        ToolbarItemGroup(placement: .secondaryAction) {
            Button {
                runValidation()
            } label: {
                Label("Validate", systemImage: "checkmark.shield")
            }
            .help("Check study completeness (⌘⇧V)")
            .disabled(!project.isScaffolded)
            
            Button {
                showingAddComponent = true
            } label: {
                Label("Add Component", systemImage: "plus.rectangle")
            }
            .help("Add a new study component")
            .disabled(!project.isScaffolded)
            
            Button {
                showingGraph = true
            } label: {
                Label("Graph View", systemImage: "point.3.connected.trianglepath.dotted")
            }
            .help("View study as a visual graph")
            .disabled(!project.isScaffolded)
        }
        
        // RIGHT GROUP: Output pipeline
        ToolbarItemGroup(placement: .primaryAction) {
            
            // Export Raw — menu with format options
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
                Label("Export Raw", systemImage: "square.and.arrow.up")
            }
            .help("Export structured data without LLM processing")
            .disabled(!project.isScaffolded)
            
            // Draft Protocol — gated by validation
            Button {
                // Run a quick validation check first
                let report = ValidationService.validate(project)
                if report.isValid {
                    showingDraftView = true
                } else {
                    // Show validation report so the user knows what to fix
                    validationReport = report
                    showingValidation = true
                }
            } label: {
                Label("Draft Protocol", systemImage: "apple.intelligence")
            }
            .help("Generate protocol draft with local AI")
            .disabled(!project.isScaffolded)
        }
    }
    
    // MARK: - Validation
    
    private func runValidation() {
        validationReport = ValidationService.validate(project)
        
        // Update project status based on validation result
        if let report = validationReport {
            if report.isValid && project.status == .draft {
                project.status = .validationReady
                try? modelContext.save()
            }
        }
        
        showingValidation = true
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
            Section {
                overviewCard
            }
            
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
