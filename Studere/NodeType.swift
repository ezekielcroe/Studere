import Foundation

// MARK: - NodeType
// The kind of research component a block represents.
// Organized into families matching the spec's Block Palette (§4.1).

enum NodeType: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }
    
    // Design Blocks — the architectural choice
    case longitudinal
    case crossSectional
    case rct
    case steppedWedge
    case adaptive
    
    // Entity Blocks — who and what
    case targetPopulation
    case controlGroup
    case intervention
    case outcomeMeasure
    
    // Method Blocks — how data is gathered
    case survey
    case interview
    case biometricSampling
    
    // Supporting Blocks — methodological scaffolding
    case randomizationStrategy
    case blindingProtocol
    case controlCondition
    case sampleSizeJustification
    case rationale
    
    // MARK: - Display
    
    var displayName: String {
        switch self {
        case .longitudinal:             return "Longitudinal"
        case .crossSectional:           return "Cross-Sectional"
        case .rct:                      return "Randomized Controlled Trial"
        case .steppedWedge:             return "Stepped-Wedge"
        case .adaptive:                 return "Adaptive Design"
        case .targetPopulation:         return "Target Population"
        case .controlGroup:             return "Control Group"
        case .intervention:             return "Intervention"
        case .outcomeMeasure:           return "Outcome Measure"
        case .survey:                   return "Survey"
        case .interview:                return "Interview"
        case .biometricSampling:        return "Biometric Sampling"
        case .randomizationStrategy:    return "Randomization Strategy"
        case .blindingProtocol:         return "Blinding Protocol"
        case .controlCondition:         return "Control Condition"
        case .sampleSizeJustification:  return "Sample Size Justification"
        case .rationale:                return "Scientific Rationale"
        }
    }
    
    var shortDescription: String {
        switch self {
        case .longitudinal:             return "Tracks participants over time"
        case .crossSectional:           return "Captures a snapshot at one point in time"
        case .rct:                      return "Randomly assigns participants to groups"
        case .steppedWedge:             return "Clusters cross over from control to intervention"
        case .adaptive:                 return "Design evolves based on interim results"
        case .targetPopulation:         return "Who is being studied"
        case .controlGroup:             return "The comparison group"
        case .intervention:             return "What is being tested"
        case .outcomeMeasure:           return "What is being measured"
        case .survey:                   return "Questionnaire-based data collection"
        case .interview:                return "Conversational data collection"
        case .biometricSampling:        return "Biological sample collection"
        case .randomizationStrategy:    return "How participants are assigned to groups"
        case .blindingProtocol:         return "Who knows about group assignments"
        case .controlCondition:         return "What the comparison group receives"
        case .sampleSizeJustification:  return "Why this many participants"
        case .rationale:                return "The scientific case for this study"
        }
    }
    
    var category: NodeCategory {
        switch self {
        case .longitudinal, .crossSectional, .rct, .steppedWedge, .adaptive:
            return .design
        case .targetPopulation, .controlGroup, .intervention, .outcomeMeasure:
            return .entity
        case .survey, .interview, .biometricSampling:
            return .method
        case .randomizationStrategy, .blindingProtocol, .controlCondition,
             .sampleSizeJustification, .rationale:
            return .supporting
        }
    }
    
    var isDesignType: Bool { category == .design }
    
    /// The SF Symbol icon for this block type.
    var iconName: String {
        switch self {
        case .longitudinal:             return "chart.line.uptrend.xyaxis"
        case .crossSectional:           return "camera.viewfinder"
        case .rct:                      return "dice"
        case .steppedWedge:             return "stairs"
        case .adaptive:                 return "arrow.triangle.branch"
        case .targetPopulation:         return "person.3"
        case .controlGroup:             return "person.2.slash"
        case .intervention:             return "syringe"
        case .outcomeMeasure:           return "target"
        case .survey:                   return "list.clipboard"
        case .interview:                return "bubble.left.and.bubble.right"
        case .biometricSampling:        return "cross.vial"
        case .randomizationStrategy:    return "shuffle"
        case .blindingProtocol:         return "eye.slash"
        case .controlCondition:         return "arrow.left.arrow.right"
        case .sampleSizeJustification:  return "number"
        case .rationale:                return "lightbulb"
        }
    }
}

// MARK: - NodeCategory

enum NodeCategory: String, Codable, CaseIterable {
    case design
    case entity
    case method
    case supporting
    
    var displayName: String {
        switch self {
        case .design:       return "Study Design"
        case .entity:       return "Entities"
        case .method:       return "Data Collection"
        case .supporting:   return "Supporting"
        }
    }
    
    var colorName: String {
        switch self {
        case .design:       return "designBlue"
        case .entity:       return "entityGreen"
        case .method:       return "methodOrange"
        case .supporting:   return "supportingPurple"
        }
    }
}
