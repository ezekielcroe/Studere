import Foundation

// MARK: - ProtocolSection
// Maps to SPIRIT guideline sections (§6.1).
// Used by the Parsing Engine (Phase 5) to organize inspector data
// into the correct protocol structure for LLM transcription.

enum ProtocolSection: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }
    
    case researchQuestion
    case scientificRationale
    case methodologyAndDesign
    case participants
    case sampleSizeAndPower
    case dataCollection
    case proposedDataAnalysis
    
    var displayName: String {
        switch self {
        case .researchQuestion:       return "Research Question"
        case .scientificRationale:    return "Scientific Rationale"
        case .methodologyAndDesign:   return "Methodology & Study Design"
        case .participants:           return "Participants"
        case .sampleSizeAndPower:     return "Sample Size & Power"
        case .dataCollection:         return "Data Collection"
        case .proposedDataAnalysis:   return "Proposed Data Analysis"
        }
    }
    
    var sectionNumber: Int {
        switch self {
        case .researchQuestion:       return 1
        case .scientificRationale:    return 2
        case .methodologyAndDesign:   return 3
        case .participants:           return 4
        case .sampleSizeAndPower:     return 5
        case .dataCollection:         return 6
        case .proposedDataAnalysis:   return 7
        }
    }
    
    /// Which block types contribute content to this protocol section (§6.1 table).
    var sourceNodeTypes: [NodeType] {
        switch self {
        case .researchQuestion:
            return [.outcomeMeasure, .targetPopulation, .intervention]
        case .scientificRationale:
            return [.rationale]
        case .methodologyAndDesign:
            return [.rct, .crossSectional, .longitudinal, .steppedWedge, .adaptive,
                    .randomizationStrategy, .blindingProtocol, .controlCondition]
        case .participants:
            return [.targetPopulation, .controlGroup]
        case .sampleSizeAndPower:
            return [.sampleSizeJustification, .targetPopulation]
        case .dataCollection:
            return [.survey, .interview, .biometricSampling]
        case .proposedDataAnalysis:
            return [.outcomeMeasure, .rct, .crossSectional, .longitudinal,
                    .steppedWedge, .adaptive]
        }
    }
}
