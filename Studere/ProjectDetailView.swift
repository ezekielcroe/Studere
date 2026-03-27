import SwiftUI
import SwiftData

// MARK: - ProjectDetailView
// Shows the scaffolded study as an ordered list of components.
//
// Keyboard navigation:
//   ↑/↓     — Move selection between components (native List behavior)
//   Return  — Open the inspector for the selected component
//   ⌘S      — Save (handled by parent ContentView)

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: ResearchProject
    var onSave: (() -> Void)?
    
    @State private var inspectorNode: ResearchNode?
    @State private var selectedNodeID: ResearchNode.ID?
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    onSave?()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut("s", modifiers: .command)
                .help("Save (⌘S)")
            }
        }
        .sheet(item: $inspectorNode) { node in
            NodeInspectorSheet(
                node: node,
                allNodes: project.scaffoldedNodes,
                onNavigate: navigateToNode,
                onSave: onSave
            )
        }
        .sheet(isPresented: $showingSetup) {
            StudySetupView(project: project) {
                showingSetup = false
            }
        }
    }
    
    // MARK: - Setup Prompt
    
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
        List(selection: $selectedNodeID) {
            Section {
                overviewCard
            }
            
            Section {
                ForEach(project.scaffoldedNodes) { node in
                    ComponentRowView(node: node)
                        .tag(node.id)
                        .contentShape(Rectangle())
                        .onTapGesture { openInspector(for: node) }
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
                footerText
            }
            
            if !project.edges.isEmpty {
                Section("Connections") {
                    ForEach(project.edges) { edge in
                        ConnectionRowView(edge: edge)
                    }
                }
            }
        }
        // Return key opens the inspector for the keyboard-selected row
        .onKeyPress(.return) {
            if let nodeID = selectedNodeID,
               let node = project.scaffoldedNodes.first(where: { $0.id == nodeID }) {
                openInspector(for: node)
                return .handled
            }
            return .ignored
        }
    }
    
    private var footerText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tap any component to answer its inspector questions.")
                .font(.caption)
            #if os(macOS)
            Text("Use ↑↓ to navigate, Return to open, ⌘S to save.")
                .font(.caption)
                .foregroundStyle(.tertiary)
            #endif
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
                        .onSubmit { onSave?() }
                    
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
    
    // MARK: - Actions
    
    private func openInspector(for node: ResearchNode) {
        inspectorNode = node
    }
    
    /// Called from the inspector's next/previous buttons to switch
    /// to a different component without closing the sheet.
    private func navigateToNode(_ node: ResearchNode) {
        inspectorNode = node
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
