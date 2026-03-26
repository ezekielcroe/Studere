import Foundation

// MARK: - EdgeType
// The kind of methodological relationship between two connected blocks.
//
// KEY CHANGE: Edge types are now INFERRED from the pair of connected
// block types, not chosen by the user. The relationship between
// "Population → Intervention" is always "receives" — that's a fact
// about research methodology, not a user choice.

enum EdgeType: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }
    
    case receives           // Population receives Intervention
    case comparedWith       // Intervention vs Control Condition
    case measuredBy         // Outcome measured by Survey/Interview/Biometric
    case assignedVia        // Population assigned via Randomization
    case blindedBy          // Study blinded by Blinding Protocol
    case produces           // Intervention produces Outcome
    case determines         // Sample Size determines Population size
    case motivates          // Rationale motivates the Study Design
    case governs            // Study Design governs structure
    case observedIn         // Outcome observed in Population
    
    var displayName: String {
        switch self {
        case .receives:         return "receives"
        case .comparedWith:     return "compared with"
        case .measuredBy:       return "measured by"
        case .assignedVia:      return "assigned via"
        case .blindedBy:        return "blinded by"
        case .produces:         return "produces"
        case .determines:       return "determines"
        case .motivates:        return "motivates"
        case .governs:          return "governs"
        case .observedIn:       return "observed in"
        }
    }
    
    var description: String {
        switch self {
        case .receives:         return "The population receives this intervention"
        case .comparedWith:     return "These groups are being compared"
        case .measuredBy:       return "This outcome is measured using this method"
        case .assignedVia:      return "Participants are assigned to groups using this strategy"
        case .blindedBy:        return "Knowledge of assignments is restricted by this protocol"
        case .produces:         return "The intervention is expected to affect this outcome"
        case .determines:       return "The sample size calculation determines the target enrollment"
        case .motivates:        return "The scientific rationale motivates the study design"
        case .governs:          return "The study design governs this component"
        case .observedIn:       return "This outcome is observed in the study population"
        }
    }
    
    /// Arrow direction hint for display
    var arrowIcon: String {
        switch self {
        case .comparedWith:     return "arrow.left.arrow.right"
        case .receives:         return "arrow.right"
        case .measuredBy:       return "arrow.right"
        case .assignedVia:      return "arrow.right"
        case .blindedBy:        return "eye.slash"
        case .produces:         return "arrow.right"
        case .determines:       return "arrow.right"
        case .motivates:        return "arrow.right"
        case .governs:          return "arrow.right"
        case .observedIn:       return "arrow.right"
        }
    }
}

// MARK: - EdgeLineStyle

enum EdgeLineStyle: String, Codable {
    case solidArrow
    case dashed
    case dotted
    case boldArrow
}
