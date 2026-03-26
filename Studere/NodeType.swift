import Foundation

// MARK: - NodeType
// Represents the category of a research block on the canvas.
// Organized into three families matching the spec's Block Palette (§4.1):
//   - Design Blocks (study architecture)
//   - Entity Blocks (who/what is being studied)
//   - Method Blocks (how data is collected)

enum NodeType: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }
    
    // MARK: Design Blocks
    case longitudinal
    case crossSectional
    case rct
    case steppedWedge
    case adaptive
    
    // MARK: Entity Blocks
    case targetPopulation
    case controlGroup
    case intervention
    case outcomeMeasure
    
    // MARK: Method Blocks
    case survey
    case interview
    case biometricSampling
    
    // MARK: Supporting Blocks (surfaced automatically by design blocks)
    case randomizationStrategy
    case blindingProtocol
    case controlCondition
    case sampleSizeJustification
    case rationale
    
    // MARK: - Display Properties
    
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
    
    /// Blocks available in the initial simplified palette (§4.5 Progressive Disclosure).
    /// Advanced blocks unlock as users complete projects.
    var isBasicBlock: Bool {
        switch self {
        case .crossSectional, .rct, .longitudinal,
             .targetPopulation, .intervention, .outcomeMeasure, .controlGroup,
             .survey, .interview,
             .randomizationStrategy, .sampleSizeJustification, .rationale:
            return true
        default:
            return false
        }
    }
    
    /// When a Design block is placed, these supporting blocks should be
    /// prompted to the user (§4.1). Returns an empty array for non-design types.
    var requiredDownstreamBlocks: [NodeType] {
        switch self {
        case .rct:
            return [.randomizationStrategy, .blindingProtocol,
                    .controlCondition, .outcomeMeasure, .sampleSizeJustification]
        case .longitudinal:
            return [.targetPopulation, .outcomeMeasure, .sampleSizeJustification]
        case .crossSectional:
            return [.targetPopulation, .outcomeMeasure]
        case .steppedWedge:
            return [.randomizationStrategy, .controlCondition,
                    .outcomeMeasure, .sampleSizeJustification]
        case .adaptive:
            return [.outcomeMeasure, .sampleSizeJustification, .randomizationStrategy]
        default:
            return []
        }
    }
}

// MARK: - NodeCategory
// Used for color-coding blocks on the palette and canvas.

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
    
    /// Color-coding per spec §4.1. Returns a named color string
    /// to be resolved against the asset catalog or SwiftUI built-ins.
    var colorName: String {
        switch self {
        case .design:       return "designBlue"
        case .entity:       return "entityGreen"
        case .method:       return "methodOrange"
        case .supporting:   return "supportingPurple"
        }
    }
}
