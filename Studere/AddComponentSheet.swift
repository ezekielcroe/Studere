import SwiftUI
import SwiftData

// MARK: - AddComponentSheet
// Allows researchers to add additional components to an existing scaffold.
// The component types offered are filtered to those that make sense for
// the current study design. Edges are auto-wired based on type rules.

struct AddComponentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let project: ResearchProject
    /// Called after a new node is inserted so the parent can select it.
    var onComponentAdded: ((ResearchNode) -> Void)?
    
    @State private var selectedType: NodeType?
    @State private var customTitle: String = ""
    
    /// Node types that can be added to the current design.
    /// Excludes design blocks (you can't add a second RCT to an RCT)
    /// and blocks that are already present as singletons (rationale).
    private var availableTypes: [NodeCategory: [NodeType]] {
        let existingTypes = Set((project.nodes ?? []).map(\.nodeType))
        
        // These types make sense to add multiples of
        let addableTypes: [NodeType] = [
            .outcomeMeasure,
            .intervention,
            .controlGroup,
            .survey,
            .interview,
            .biometricSampling,
        ]
        
        // These types can be added if not already present
        let singletonTypes: [NodeType] = [
            .targetPopulation,
            .controlCondition,
            .randomizationStrategy,
            .blindingProtocol,
            .sampleSizeJustification,
            .rationale,
        ]
        
        var result: [NodeCategory: [NodeType]] = [:]
        
        for type in addableTypes {
            result[type.category, default: []].append(type)
        }
        
        for type in singletonTypes where !existingTypes.contains(type) {
            result[type.category, default: []].append(type)
        }
        
        return result
    }
    
    private var sortedCategories: [NodeCategory] {
        // Display order: entity → method → supporting
        [.entity, .method, .supporting].filter { availableTypes[$0] != nil }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Add a new component to your \(project.designType?.displayName ?? "study"). Connections will be wired automatically.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                ForEach(sortedCategories, id: \.self) { category in
                    if let types = availableTypes[category] {
                        Section(category.displayName) {
                            ForEach(types) { nodeType in
                                typeRow(nodeType)
                            }
                        }
                    }
                }
                
                if selectedType != nil {
                    Section("Component Name") {
                        TextField("e.g., Secondary Outcome", text: $customTitle)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
            .navigationTitle("Add Component")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addComponent() }
                        .disabled(selectedType == nil)
                }
            }
        }
        .onChange(of: selectedType) { _, newType in
            // Pre-fill a sensible default title
            if let type = newType, customTitle.isEmpty {
                let existingCount = (project.nodes ?? [])
                    .filter { $0.nodeType == type }
                    .count
                if existingCount > 0 {
                    customTitle = "\(type.displayName) \(existingCount + 1)"
                } else {
                    customTitle = type.displayName
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 440, minHeight: 480)
        #endif
    }
    
    // MARK: - Type Row
    
    private func typeRow(_ nodeType: NodeType) -> some View {
        let isSelected = selectedType == nodeType
        
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedType = nodeType
                // Reset title when switching types
                let existingCount = (project.nodes ?? [])
                    .filter { $0.nodeType == nodeType }
                    .count
                customTitle = existingCount > 0
                    ? "\(nodeType.displayName) \(existingCount + 1)"
                    : nodeType.displayName
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: nodeType.iconName)
                    .font(.body)
                    .frame(width: 28, height: 28)
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(categoryColor(nodeType.category))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(nodeType.displayName)
                        .font(.subheadline.weight(.medium))
                    Text(nodeType.shortDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Add Component
    
    private func addComponent() {
        guard let nodeType = selectedType else { return }
        
        let title = customTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = title.isEmpty ? nodeType.displayName : title
        
        // 1. Create the new node
        let newNode = ResearchNode(nodeType: nodeType, title: finalTitle)
        newNode.project = project
        newNode.isScaffolded = true
        newNode.isRequired = false // User-added components are optional by default
        // Give it a unique slotID so it sorts after template nodes
        newNode.slotID = "added_\(UUID().uuidString.prefix(8))"
        modelContext.insert(newNode)
        
        // 2. Auto-wire edges based on type relationships
        autoWireEdges(for: newNode)
        
        // 3. Save
        do {
            try modelContext.save()
        } catch {
            print("Failed to save added component: \(error.localizedDescription)")
        }
        
        // 4. Notify parent and dismiss
        onComponentAdded?(newNode)
        dismiss()
    }
    
    // MARK: - Auto-Wiring
    
    /// Creates sensible default edges for a newly added node based on
    /// what already exists in the project. Follows the same relationship
    /// rules used by the templates.
    private func autoWireEdges(for newNode: ResearchNode) {
        let existingNodes = project.nodes ?? []
        
        switch newNode.nodeType {
            
        case .outcomeMeasure:
            // Outcome → observedIn → Population
            if let population = existingNodes.first(where: { $0.nodeType == .targetPopulation }) {
                insertEdge(from: newNode, to: population, type: .observedIn)
            }
            // Outcome → measuredBy → first data collection method
            if let method = existingNodes.first(where: { $0.category == .method }) {
                insertEdge(from: newNode, to: method, type: .measuredBy)
            }
            
        case .intervention:
            // Population → receives → Intervention
            if let population = existingNodes.first(where: { $0.nodeType == .targetPopulation }) {
                insertEdge(from: population, to: newNode, type: .receives)
            }
            // Intervention → produces → first outcome
            if let outcome = existingNodes.first(where: { $0.nodeType == .outcomeMeasure }) {
                insertEdge(from: newNode, to: outcome, type: .produces)
            }
            
        case .controlGroup:
            // Compared with first intervention
            if let intervention = existingNodes.first(where: { $0.nodeType == .intervention }) {
                insertEdge(from: intervention, to: newNode, type: .comparedWith)
            }
            
        case .survey, .interview, .biometricSampling:
            // First outcome → measuredBy → this method
            if let outcome = existingNodes.first(where: { $0.nodeType == .outcomeMeasure }) {
                insertEdge(from: outcome, to: newNode, type: .measuredBy)
            }
            
        default:
            break
        }
    }
    
    private func insertEdge(from source: ResearchNode, to target: ResearchNode, type: EdgeType) {
        let edge = ResearchEdge(source: source, target: target, relationshipType: type)
        edge.project = project
        edge.isScaffolded = true
        modelContext.insert(edge)
    }
    
    // MARK: - Helpers
    
    private func categoryColor(_ category: NodeCategory) -> Color {
        switch category {
        case .design:       return .blue
        case .entity:       return .green
        case .method:       return .orange
        case .supporting:   return .purple
        }
    }
}
