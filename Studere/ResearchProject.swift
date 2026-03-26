import Foundation
import SwiftData

// MARK: - ResearchProject
// Top-level container for a study design.
// The spec doesn't explicitly define this, but we need a grouping model
// so users can manage multiple study designs and so progressive disclosure
// can track completed project count (§4.5).

@Model
final class ResearchProject {
    
    // MARK: - Stored Properties
    
    var id: UUID
    var title: String
    var createdAt: Date
    var modifiedAt: Date
    
    /// Current status of this project
    var statusRaw: String
    
    /// All nodes belonging to this project
    @Relationship(deleteRule: .cascade, inverse: \ResearchNode.project)
    var nodes: [ResearchNode]
    
    /// All edges belonging to this project
    @Relationship(deleteRule: .cascade, inverse: \ResearchEdge.project)
    var edges: [ResearchEdge]
    
    // MARK: - Computed Properties
    
    var status: ProjectStatus {
        get { ProjectStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }
    
    // MARK: - Initialization
    
    init(title: String = "Untitled Study") {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.statusRaw = ProjectStatus.draft.rawValue
        self.nodes = []
        self.edges = []
    }
    
    // MARK: - Convenience Methods
    
    /// Touch the modification date whenever the project changes.
    func touch() {
        self.modifiedAt = Date()
    }
    
    /// Retrieve all nodes of a given type within this project.
    func nodes(ofType type: NodeType) -> [ResearchNode] {
        nodes.filter { $0.nodeType == type }
    }
    
    /// Check whether this project has at least one design block placed.
    var hasDesignBlock: Bool {
        nodes.contains { $0.nodeType.category == .design }
    }
}

// MARK: - ProjectStatus

enum ProjectStatus: String, Codable, CaseIterable {
    case draft              // In progress on the canvas
    case validationReady    // Canvas complete, ready for validation
    case validated          // Passed validation, ready for protocol generation
    case protocolDrafted    // LLM draft generated, under review
    case completed          // User has endorsed and exported the protocol
    
    var displayName: String {
        switch self {
        case .draft:            return "Draft"
        case .validationReady:  return "Ready for Validation"
        case .validated:        return "Validated"
        case .protocolDrafted:  return "Protocol Drafted"
        case .completed:        return "Completed"
        }
    }
}
