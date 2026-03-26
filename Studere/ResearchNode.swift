import Foundation
import SwiftData

// MARK: - ResearchNode
// A single research component in the study design.
//
// KEY CHANGES:
//   - slotID: links this node back to its SlotDefinition in the template
//   - isScaffolded: true if created by the scaffold builder (vs manually added)
//   - isRequired: true if this is a required component for the design type

@Model
final class ResearchNode {
    
    var id: UUID
    var title: String
    var nodeTypeRaw: String
    var inspectorData: [String: String]
    
    // Canvas position (for future canvas phase)
    var positionX: Double
    var positionY: Double
    
    // Scaffold metadata
    /// Links this node to its SlotDefinition.id in the template.
    var slotID: String?
    /// True if created by ScaffoldBuilder (not manually added).
    var isScaffolded: Bool
    /// True if this is a required component of the study design.
    var isRequired: Bool
    
    // Relationships
    var project: ResearchProject?
    
    @Relationship(deleteRule: .cascade, inverse: \ResearchEdge.sourceNode)
    var outgoingEdges: [ResearchEdge]
    
    @Relationship(deleteRule: .cascade, inverse: \ResearchEdge.targetNode)
    var incomingEdges: [ResearchEdge]
    
    // MARK: - Computed Properties
    
    var nodeType: NodeType {
        get { NodeType(rawValue: nodeTypeRaw) ?? .outcomeMeasure }
        set { nodeTypeRaw = newValue.rawValue }
    }
    
    var category: NodeCategory {
        nodeType.category
    }
    
    var downstreamNodes: [ResearchNode] {
        outgoingEdges.compactMap { $0.targetNode }
    }
    
    var upstreamNodes: [ResearchNode] {
        incomingEdges.compactMap { $0.sourceNode }
    }
    
    /// Inspector fields that have non-empty values.
    var completedFields: [String: String] {
        inspectorData.filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    /// How many required questions have been answered.
    var completionProgress: (filled: Int, total: Int) {
        let required = InspectorQuestionBank.requiredKeys(for: nodeType)
        let filled = required.filter { key in
            let val = inspectorData[key] ?? ""
            return !val.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count
        return (filled, required.count)
    }
    
    /// True if all required inspector fields are filled.
    var isComplete: Bool {
        let progress = completionProgress
        return progress.total == 0 || progress.filled == progress.total
    }
    
    /// Returns the edge types connecting this node, for display.
    var relationshipSummary: String {
        let incoming = incomingEdges.compactMap { edge -> String? in
            guard let source = edge.sourceNode else { return nil }
            return "\(source.title) → \(edge.relationshipType.displayName)"
        }
        let outgoing = outgoingEdges.compactMap { edge -> String? in
            guard let target = edge.targetNode else { return nil }
            return "\(edge.relationshipType.displayName) → \(target.title)"
        }
        return (incoming + outgoing).joined(separator: ", ")
    }
    
    // MARK: - Initialization
    
    init(
        nodeType: NodeType,
        title: String? = nil,
        positionX: Double = 0,
        positionY: Double = 0
    ) {
        self.id = UUID()
        self.title = title ?? nodeType.displayName
        self.nodeTypeRaw = nodeType.rawValue
        self.inspectorData = [:]
        self.positionX = positionX
        self.positionY = positionY
        self.slotID = nil
        self.isScaffolded = false
        self.isRequired = false
        self.outgoingEdges = []
        self.incomingEdges = []
    }
    
    // MARK: - Inspector Helpers
    
    func answer(for questionKey: String) -> String {
        inspectorData[questionKey] ?? ""
    }
    
    func setAnswer(_ value: String, for questionKey: String) {
        inspectorData[questionKey] = value
        project?.touch()
    }
}
