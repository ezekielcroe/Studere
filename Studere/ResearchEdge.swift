import Foundation
import SwiftData

// MARK: - ResearchEdge
// A directed connection between two ResearchNodes on the canvas.
// Together with ResearchNode, these form the DAG described in §3.
// Users create edges by dragging between output/input ports on the canvas (§4.2)
// and define the relationship type by tapping the edge.

@Model
final class ResearchEdge {
    
    // MARK: - Stored Properties
    
    var id: UUID
    
    /// Persisted as raw string; use the computed `relationshipType` property.
    var relationshipTypeRaw: String
    
    /// The node this edge originates from.
    var sourceNode: ResearchNode?
    
    /// The node this edge points to.
    var targetNode: ResearchNode?
    
    /// Parent project (for cascading deletes and queries)
    var project: ResearchProject?
    
    // MARK: - Computed Properties
    
    var relationshipType: EdgeType {
        get { EdgeType(rawValue: relationshipTypeRaw) ?? .observational }
        set { relationshipTypeRaw = newValue.rawValue }
    }
    
    /// Convenience: is this edge fully connected?
    var isComplete: Bool {
        sourceNode != nil && targetNode != nil
    }
    
    // MARK: - Initialization
    
    init(
        source: ResearchNode,
        target: ResearchNode,
        relationshipType: EdgeType = .observational
    ) {
        self.id = UUID()
        self.sourceNode = source
        self.targetNode = target
        self.relationshipTypeRaw = relationshipType.rawValue
    }
}
