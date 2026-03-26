import Foundation
import SwiftData

// MARK: - ResearchEdge
// A directed methodological relationship between two ResearchNodes.
//
// KEY CHANGE: Edges are now primarily created by the ScaffoldBuilder
// with their relationship type pre-determined. The user no longer
// manually creates edges or chooses edge types.

@Model
final class ResearchEdge {
    
    var id: UUID
    var relationshipTypeRaw: String
    var sourceNode: ResearchNode?
    var targetNode: ResearchNode?
    var project: ResearchProject?
    
    /// True if created by ScaffoldBuilder (vs manually added).
    var isScaffolded: Bool
    
    // MARK: - Computed Properties
    
    var relationshipType: EdgeType {
        get { EdgeType(rawValue: relationshipTypeRaw) ?? .governs }
        set { relationshipTypeRaw = newValue.rawValue }
    }
    
    var isComplete: Bool {
        sourceNode != nil && targetNode != nil
    }
    
    // MARK: - Initialization
    
    init(
        source: ResearchNode,
        target: ResearchNode,
        relationshipType: EdgeType = .governs
    ) {
        self.id = UUID()
        self.sourceNode = source
        self.targetNode = target
        self.relationshipTypeRaw = relationshipType.rawValue
        self.isScaffolded = false
    }
}
