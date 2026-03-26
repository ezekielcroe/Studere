import Foundation
import SwiftData

// MARK: - ResearchProject
// Top-level container for a study design.
//
// KEY CHANGE: Now tracks the chosen study design type, which
// determines the scaffold structure. The project starts empty,
// the user picks a design type during setup, and the scaffold
// builder populates it.

@Model
final class ResearchProject {
    
    var id: UUID
    var title: String
    var createdAt: Date
    var modifiedAt: Date
    var statusRaw: String
    
    /// The study design type chosen during setup.
    /// Nil until the user completes the design selection step.
    var designTypeRaw: String?
    
    @Relationship(deleteRule: .cascade, inverse: \ResearchNode.project)
    var nodes: [ResearchNode]
    
    @Relationship(deleteRule: .cascade, inverse: \ResearchEdge.project)
    var edges: [ResearchEdge]
    
    // MARK: - Computed Properties
    
    var status: ProjectStatus {
        get { ProjectStatus(rawValue: statusRaw) ?? .setup }
        set { statusRaw = newValue.rawValue }
    }
    
    var designType: NodeType? {
        get {
            guard let raw = designTypeRaw else { return nil }
            return NodeType(rawValue: raw)
        }
        set { designTypeRaw = newValue?.rawValue }
    }
    
    /// Whether the scaffold has been built (design type chosen + blocks created).
    var isScaffolded: Bool {
        designType != nil && !nodes.isEmpty
    }
    
    /// The template for this project's design type.
    var template: StudyDesignTemplate? {
        guard let dt = designType else { return nil }
        return StudyDesignTemplate.template(for: dt)
    }
    
    // MARK: - Initialization
    
    init(title: String = "Untitled Study") {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.statusRaw = ProjectStatus.setup.rawValue
        self.designTypeRaw = nil
        self.nodes = []
        self.edges = []
    }
    
    // MARK: - Convenience
    
    func touch() {
        self.modifiedAt = Date()
    }
    
    func nodes(ofType type: NodeType) -> [ResearchNode] {
        nodes.filter { $0.nodeType == type }
    }
    
    /// Find a node by its slot ID (assigned during scaffolding).
    func node(forSlot slotID: String) -> ResearchNode? {
        nodes.first { $0.slotID == slotID }
    }
    
    /// All scaffolded nodes in template order.
    var scaffoldedNodes: [ResearchNode] {
        guard let template = template else { return nodes }
        let slotOrder = template.slots.map(\.id)
        return nodes.sorted { a, b in
            let indexA = slotOrder.firstIndex(of: a.slotID ?? "") ?? Int.max
            let indexB = slotOrder.firstIndex(of: b.slotID ?? "") ?? Int.max
            return indexA < indexB
        }
    }
    
    /// Overall completion: how many required inspector fields are filled.
    var completionProgress: (filled: Int, total: Int) {
        var filled = 0
        var total = 0
        for node in nodes {
            let required = InspectorQuestionBank.requiredKeys(for: node.nodeType)
            total += required.count
            filled += required.filter { key in
                let val = node.inspectorData[key] ?? ""
                return !val.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }.count
        }
        return (filled, total)
    }
}

// MARK: - ProjectStatus

enum ProjectStatus: String, Codable, CaseIterable {
    case setup              // Design type not yet chosen
    case draft              // Scaffold built, user filling in inspector data
    case validationReady    // All required fields filled
    case validated          // Passed validation
    case protocolDrafted    // LLM draft generated
    case completed          // User has endorsed and exported
    
    var displayName: String {
        switch self {
        case .setup:            return "Setting Up"
        case .draft:            return "In Progress"
        case .validationReady:  return "Ready for Validation"
        case .validated:        return "Validated"
        case .protocolDrafted:  return "Protocol Drafted"
        case .completed:        return "Completed"
        }
    }
    
    var iconName: String {
        switch self {
        case .setup:            return "wrench"
        case .draft:            return "pencil"
        case .validationReady:  return "checkmark.circle"
        case .validated:        return "checkmark.seal"
        case .protocolDrafted:  return "doc.text"
        case .completed:        return "checkmark.seal.fill"
        }
    }
}
