import SwiftUI
import SwiftData

// MARK: - AddEdgeSheet
// Creates a directed edge between two existing nodes.
// On the canvas (Phase 4) this will be done by dragging between ports,
// but in Phase 1 we use picker-based selection to validate the data model.

struct AddEdgeSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let project: ResearchProject
    
    @State private var sourceNode: ResearchNode?
    @State private var targetNode: ResearchNode?
    @State private var edgeType: EdgeType = .observational
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("From") {
                    Picker("Source Block", selection: $sourceNode) {
                        Text("Select a block…").tag(nil as ResearchNode?)
                        ForEach(project.nodes) { node in
                            Text("\(node.title) (\(node.nodeType.displayName))")
                                .tag(node as ResearchNode?)
                        }
                    }
                }
                
                Section("To") {
                    Picker("Target Block", selection: $targetNode) {
                        Text("Select a block…").tag(nil as ResearchNode?)
                        ForEach(availableTargets) { node in
                            Text("\(node.title) (\(node.nodeType.displayName))")
                                .tag(node as ResearchNode?)
                        }
                    }
                }
                
                Section("Relationship Type") {
                    Picker("Type", selection: $edgeType) {
                        ForEach(EdgeType.allCases) { type in
                            VStack(alignment: .leading) {
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                    
                    Text(edgeType.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Connect Blocks")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Connect") { addEdge() }
                        .disabled(sourceNode == nil || targetNode == nil)
                }
            }
            .alert("Cannot Connect", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 400)
        #endif
    }
    
    /// Exclude the source node from target options (no self-loops).
    private var availableTargets: [ResearchNode] {
        project.nodes.filter { $0.id != sourceNode?.id }
    }
    
    private func addEdge() {
        guard let source = sourceNode, let target = targetNode else { return }
        
        // DAG check: prevent duplicate edges
        let duplicate = project.edges.contains { edge in
            edge.sourceNode?.id == source.id && edge.targetNode?.id == target.id
        }
        if duplicate {
            errorMessage = "These blocks are already connected in this direction."
            showingError = true
            return
        }
        
        // Simple cycle check: prevent A→B when B→A already exists
        // (Full DAG cycle detection would use DFS; this catches the obvious case)
        let reverse = project.edges.contains { edge in
            edge.sourceNode?.id == target.id && edge.targetNode?.id == source.id
        }
        if reverse {
            errorMessage = "A connection already exists in the opposite direction. The graph must remain acyclic."
            showingError = true
            return
        }
        
        let edge = ResearchEdge(source: source, target: target, relationshipType: edgeType)
        edge.project = project
        modelContext.insert(edge)
        project.touch()
        
        dismiss()
    }
}
