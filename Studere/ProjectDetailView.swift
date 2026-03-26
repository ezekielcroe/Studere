import SwiftUI
import SwiftData

// MARK: - ProjectDetailView
// Phase 1 test UI: displays and manages nodes and edges within a project.
// Validates CRUD operations, relationship integrity, and persistence.

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: ResearchProject
    
    @State private var selectedNode: ResearchNode?
    @State private var showingAddNode = false
    @State private var showingAddEdge = false
    
    var body: some View {
        List {
            // MARK: Project Info
            Section("Study Details") {
                TextField("Title", text: $project.title)
                    .font(.title3)
                LabeledContent("Status", value: project.status.displayName)
                LabeledContent("Created", value: project.createdAt.formatted(date: .abbreviated, time: .omitted))
                LabeledContent("Modified", value: project.modifiedAt.formatted(date: .abbreviated, time: .shortened))
            }
            
            // MARK: Nodes
            Section {
                if project.nodes.isEmpty {
                    Text("No blocks yet. Add your first research block to get started.")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(nodesByCategory) { group in
                        DisclosureGroup {
                            ForEach(group.nodes) { node in
                                NodeRowView(node: node)
                                    .contentShape(Rectangle())
                                    .onTapGesture { selectedNode = node }
                            }
                            .onDelete { offsets in
                                deleteNodes(from: group.nodes, at: offsets)
                            }
                        } label: {
                            Label(group.category.displayName, systemImage: iconForCategory(group.category))
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Research Blocks")
                    Spacer()
                    Button("Add Block", systemImage: "plus.square") {
                        showingAddNode = true
                    }
                    .font(.caption)
                }
            }
            
            // MARK: Edges
            Section {
                if project.edges.isEmpty {
                    Text("No connections yet. Add blocks first, then connect them.")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(project.edges) { edge in
                        EdgeRowView(edge: edge)
                    }
                    .onDelete(perform: deleteEdges)
                }
            } header: {
                HStack {
                    Text("Connections")
                    Spacer()
                    Button("Connect", systemImage: "arrow.triangle.branch") {
                        showingAddEdge = true
                    }
                    .font(.caption)
                    .disabled(project.nodes.count < 2)
                }
            }
            
            // MARK: Validation Summary
            if !project.nodes.isEmpty {
                Section("Quick Validation") {
                    let stats = validationSummary
                    LabeledContent("Total blocks", value: "\(project.nodes.count)")
                    LabeledContent("Connections", value: "\(project.edges.count)")
                    LabeledContent("Fields completed", value: "\(stats.filled) / \(stats.total)")
                    if stats.filled < stats.total {
                        Label("\(stats.total - stats.filled) empty required fields", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle(project.title)
        .sheet(isPresented: $showingAddNode) {
            AddNodeSheet(project: project)
        }
        .sheet(isPresented: $showingAddEdge) {
            AddEdgeSheet(project: project)
        }
        .sheet(item: $selectedNode) { node in
            NodeInspectorSheet(node: node)
        }
    }
    
    // MARK: - Grouped Nodes
    
    private var nodesByCategory: [NodeGroup] {
        let grouped = Dictionary(grouping: project.nodes) { $0.category }
        return NodeCategory.allCases.compactMap { category in
            guard let nodes = grouped[category], !nodes.isEmpty else { return nil }
            return NodeGroup(category: category, nodes: nodes)
        }
    }
    
    // MARK: - Validation
    
    private var validationSummary: (filled: Int, total: Int) {
        var filled = 0
        var total = 0
        for node in project.nodes {
            let required = InspectorQuestionBank.requiredKeys(for: node.nodeType)
            total += required.count
            filled += required.filter { key in
                let val = node.inspectorData[key] ?? ""
                return !val.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }.count
        }
        return (filled, total)
    }
    
    // MARK: - Actions
    
    private func deleteNodes(from nodes: [ResearchNode], at offsets: IndexSet) {
        for index in offsets {
            let node = nodes[index]
            if selectedNode?.id == node.id { selectedNode = nil }
            modelContext.delete(node)
        }
        project.touch()
    }
    
    private func deleteEdges(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(project.edges[index])
        }
        project.touch()
    }
    
    private func iconForCategory(_ category: NodeCategory) -> String {
        switch category {
        case .design:       return "rectangle.3.group.bubble"
        case .entity:       return "person.2"
        case .method:       return "wrench.and.screwdriver"
        case .supporting:   return "puzzlepiece"
        }
    }
}

// MARK: - NodeGroup (for sectioned display)

struct NodeGroup: Identifiable {
    let category: NodeCategory
    let nodes: [ResearchNode]
    var id: String { category.rawValue }
}
