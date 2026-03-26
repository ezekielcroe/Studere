import Foundation

// MARK: - EdgeType
// Represents the kind of relationship between two connected research blocks.
// Users define this by tapping an edge on the canvas (§4.2).

enum EdgeType: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }
    
    case temporal       // "A happens before B" (e.g., baseline → follow-up)
    case comparison     // "A is compared against B" (e.g., intervention vs control)
    case observational  // "A is observed using B" (e.g., outcome measured by survey)
    case causal         // "A is hypothesized to cause B"
    
    var displayName: String {
        switch self {
        case .temporal:      return "Temporal"
        case .comparison:    return "Comparison"
        case .observational: return "Observational"
        case .causal:        return "Causal"
        }
    }
    
    var description: String {
        switch self {
        case .temporal:      return "Indicates a time-ordered sequence between components"
        case .comparison:    return "Indicates two components are being compared"
        case .observational: return "Indicates one component is measured or observed by another"
        case .causal:        return "Indicates a hypothesized causal relationship"
        }
    }
    
    /// Visual styling hint for the canvas renderer.
    /// Temporal edges might be solid arrows, comparison might be dashed, etc.
    var lineStyle: EdgeLineStyle {
        switch self {
        case .temporal:      return .solidArrow
        case .comparison:    return .dashed
        case .observational: return .dotted
        case .causal:        return .boldArrow
        }
    }
}

// MARK: - EdgeLineStyle
// Visual representation hints consumed by the canvas drawing code.

enum EdgeLineStyle: String, Codable {
    case solidArrow
    case dashed
    case dotted
    case boldArrow
}
