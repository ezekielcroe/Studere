import SwiftUI
import SwiftData

// MARK: - AddNodeSheet
// Presents available block types grouped by category.
// In Phase 1 this shows all blocks; progressive disclosure (§4.5)
// will filter by user experience level in a later phase.

struct AddNodeSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let project: ResearchProject
    @State private var customTitle: String = ""
    @State private var selectedType: NodeType?
    
    var body: some View {
        NavigationStack {
            List {
                categorySections
                
                if selectedType != nil {
                    Section("Block Title") {
                        TextField("Display name", text: $customTitle)
                    }
                }
            }
            .navigationTitle("Add Block")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addNode() }
                        .disabled(selectedType == nil)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 500)
        #endif
    }
    
    @ViewBuilder
    private var categorySections: some View {
        ForEach(NodeCategory.allCases, id: \.self) { category in
            let types = NodeType.allCases.filter { $0.category == category }
            if !types.isEmpty {
                Section(category.displayName) {
                    ForEach(types) { type in
                        nodeButton(for: type, category: category)
                    }
                }
            }
        }
    }
    
    private func nodeButton(for type: NodeType, category: NodeCategory) -> some View {
        Button {
            selectedType = type
            customTitle = type.displayName
        } label: {
            nodeButtonLabel(for: type, category: category)
        }
        .tint(.primary)
    }
    
    private func nodeButtonLabel(for type: NodeType, category: NodeCategory) -> some View {
        HStack {
            Circle()
                .fill(colorForCategory(category))
                .frame(width: 8, height: 8)
            VStack(alignment: .leading) {
                Text(type.displayName)
                    .font(.body)
                if !type.requiredDownstreamBlocks.isEmpty {
                    Text("Prompts: \(type.requiredDownstreamBlocks.map(\.displayName).joined(separator: ", "))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            if selectedType == type {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
    
    private func addNode() {
        guard let type = selectedType else { return }
        
        let node = ResearchNode(
            nodeType: type,
            title: customTitle.isEmpty ? type.displayName : customTitle
        )
        node.project = project
        modelContext.insert(node)
        project.touch()
        
        dismiss()
    }
    
    private func colorForCategory(_ category: NodeCategory) -> Color {
        switch category {
        case .design:       return .blue
        case .entity:       return .green
        case .method:       return .orange
        case .supporting:   return .purple
        }
    }
}
