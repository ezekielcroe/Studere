import Foundation
import SwiftData

// MARK: - ResearchNode
// A single block on the canvas representing a research design component.
// This is one of the two core SwiftData models defined in §3.1.
//
// The inspectorData dictionary stores all Socratic Inspector responses
// keyed by a structured naming convention:
//   "{nodeType}.{questionKey}" → user's answer text
//
// Example keys for an outcomeMeasure node:
//   "outcomeMeasure.outcomeType"         → "Continuous"
//   "outcomeMeasure.instrument"          → "PHQ-9 Depression Scale"
//   "outcomeMeasure.timePoints"          → "Baseline, 6 weeks, 12 weeks"
//   "outcomeMeasure.mcid"               → "5-point reduction"
//   "outcomeMeasure.validityConcerns"   → "Self-report bias in..."

@Model
final class ResearchNode {
    
    // MARK: - Stored Properties
    
    var id: UUID
    var title: String
    
    /// Persisted as raw string; use the computed `nodeType` property.
    var nodeTypeRaw: String
    
    /// Structured Socratic Inspector responses (§3.2).
    /// This replaces the v1.0 `specifics` field.
    /// Keys follow the pattern: "{nodeType}.{questionKey}"
    var inspectorData: [String: String]
    
    /// Canvas position
    var positionX: Double
    var positionY: Double
    
    /// Parent project
    var project: ResearchProject?
    
    /// Edges originating from this node
    @Relationship(deleteRule: .cascade, inverse: \ResearchEdge.sourceNode)
    var outgoingEdges: [ResearchEdge]
    
    /// Edges terminating at this node
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
    
    /// All nodes connected downstream from this one.
    var downstreamNodes: [ResearchNode] {
        outgoingEdges.compactMap { $0.targetNode }
    }
    
    /// All nodes connected upstream to this one.
    var upstreamNodes: [ResearchNode] {
        incomingEdges.compactMap { $0.sourceNode }
    }
    
    /// Returns inspector fields that have non-empty values.
    var completedFields: [String: String] {
        inspectorData.filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    /// Returns inspector field keys that are empty or missing.
    /// Requires knowing the expected keys for this node type —
    /// see InspectorQuestionBank for the canonical list.
    func emptyFieldKeys(expectedKeys: [String]) -> [String] {
        expectedKeys.filter { key in
            guard let value = inspectorData[key] else { return true }
            return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
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
        self.outgoingEdges = []
        self.incomingEdges = []
    }
    
    // MARK: - Inspector Data Helpers
    
    /// Read an inspector field value by question key.
    func answer(for questionKey: String) -> String {
        inspectorData[questionKey] ?? ""
    }
    
    /// Write an inspector field value.
    func setAnswer(_ value: String, for questionKey: String) {
        inspectorData[questionKey] = value
        project?.touch()
    }
}
