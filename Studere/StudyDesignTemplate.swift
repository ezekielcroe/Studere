import Foundation

// MARK: - StudyDesignTemplate
// Defines the complete scaffold for a study design type.
//
// This is the key architectural change: instead of users manually
// assembling blocks and drawing arbitrary connections, the study
// design type defines what components are needed and how they relate.
// The user's job becomes filling in content, not building topology.
//
// Each template specifies:
//   - Which blocks (slots) the design requires
//   - Which connections exist between those slots
//   - Which slots are mandatory vs optional
//   - Which slots offer a choice of block type (e.g., data collection method)

struct StudyDesignTemplate {
    let designType: NodeType
    let description: String
    let slots: [SlotDefinition]
    let connections: [ConnectionDefinition]
    
    /// Human-readable summary shown during study setup.
    var componentSummary: String {
        let required = slots.filter(\.isRequired)
        let optional = slots.filter { !$0.isRequired }
        var parts: [String] = []
        parts.append("\(required.count) required component\(required.count == 1 ? "" : "s")")
        if !optional.isEmpty {
            parts.append("\(optional.count) optional")
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - SlotDefinition
// A single "slot" in the scaffold that will become a ResearchNode.
// Each slot has a stable ID so connections can reference it.

struct SlotDefinition: Identifiable {
    let id: String                  // Stable ID, e.g. "population", "intervention"
    let label: String               // Display name, e.g. "Target Population"
    let blockType: SlotBlockType    // Fixed type or user's choice
    let isRequired: Bool            // Must be filled for protocol generation
    let helpText: String?           // Explains why this component is needed
    
    /// What block type(s) this slot can hold.
    enum SlotBlockType {
        case fixed(NodeType)                // Always this type
        case choice([NodeType], String)     // User picks; String = prompt text
    }
    
    /// Resolved node type (for fixed slots) or nil (for choice slots before user picks).
    var resolvedType: NodeType? {
        switch blockType {
        case .fixed(let type): return type
        case .choice: return nil
        }
    }
    
    /// All possible types this slot could be.
    var possibleTypes: [NodeType] {
        switch blockType {
        case .fixed(let type): return [type]
        case .choice(let types, _): return types
        }
    }
}

// MARK: - ConnectionDefinition
// A directed relationship between two slots in the scaffold.
// When the scaffold is built, this becomes a ResearchEdge.

struct ConnectionDefinition {
    let fromSlotID: String      // SlotDefinition.id of the source
    let toSlotID: String        // SlotDefinition.id of the target
    let edgeType: EdgeType      // The inferred relationship type
}


// MARK: - Template Registry
// All study design templates, keyed by NodeType.

extension StudyDesignTemplate {
    
    /// Returns the template for a given study design type.
    /// Returns nil for non-design node types.
    static func template(for designType: NodeType) -> StudyDesignTemplate? {
        switch designType {
        case .rct:              return Self.rct
        case .crossSectional:   return Self.crossSectional
        case .longitudinal:     return Self.longitudinal
        case .steppedWedge:     return Self.steppedWedge
        case .adaptive:         return Self.adaptive
        default:                return nil
        }
    }
    
    /// All available design types, ordered for the setup picker.
    static var allDesignTypes: [NodeType] {
        [.rct, .crossSectional, .longitudinal, .steppedWedge, .adaptive]
    }
    
    // MARK: - RCT Template
    
    static let rct = StudyDesignTemplate(
        designType: .rct,
        description: "Randomly assigns participants to an intervention or control group to test whether the intervention causes an effect.",
        slots: [
            SlotDefinition(
                id: "rationale",
                label: "Scientific Rationale",
                blockType: .fixed(.rationale),
                isRequired: true,
                helpText: "The scientific case for why this trial is needed."
            ),
            SlotDefinition(
                id: "population",
                label: "Target Population",
                blockType: .fixed(.targetPopulation),
                isRequired: true,
                helpText: "Who will be enrolled in the trial — inclusion/exclusion criteria."
            ),
            SlotDefinition(
                id: "intervention",
                label: "Intervention",
                blockType: .fixed(.intervention),
                isRequired: true,
                helpText: "The treatment or exposure being tested."
            ),
            SlotDefinition(
                id: "control",
                label: "Control Condition",
                blockType: .fixed(.controlCondition),
                isRequired: true,
                helpText: "What the comparison group receives (placebo, standard care, etc.)."
            ),
            SlotDefinition(
                id: "randomization",
                label: "Randomization Strategy",
                blockType: .fixed(.randomizationStrategy),
                isRequired: true,
                helpText: "How participants will be randomly assigned to groups."
            ),
            SlotDefinition(
                id: "blinding",
                label: "Blinding Protocol",
                blockType: .fixed(.blindingProtocol),
                isRequired: true,
                helpText: "Who will be blinded to group assignments and how."
            ),
            SlotDefinition(
                id: "outcome",
                label: "Primary Outcome",
                blockType: .fixed(.outcomeMeasure),
                isRequired: true,
                helpText: "The main outcome that will determine if the intervention works."
            ),
            SlotDefinition(
                id: "dataCollection",
                label: "Data Collection Method",
                blockType: .choice(
                    [.survey, .interview, .biometricSampling],
                    "How will you measure the primary outcome?"
                ),
                isRequired: true,
                helpText: "The method used to gather outcome data."
            ),
            SlotDefinition(
                id: "sampleSize",
                label: "Sample Size Justification",
                blockType: .fixed(.sampleSizeJustification),
                isRequired: true,
                helpText: "The statistical basis for how many participants are needed."
            ),
        ],
        connections: [
            // Population relationships
            ConnectionDefinition(fromSlotID: "population", toSlotID: "intervention", edgeType: .receives),
            ConnectionDefinition(fromSlotID: "population", toSlotID: "control", edgeType: .receives),
            // Comparison
            ConnectionDefinition(fromSlotID: "intervention", toSlotID: "control", edgeType: .comparedWith),
            // Assignment
            ConnectionDefinition(fromSlotID: "randomization", toSlotID: "population", edgeType: .assignedVia),
            // Blinding
            ConnectionDefinition(fromSlotID: "blinding", toSlotID: "intervention", edgeType: .blindedBy),
            // Outcomes
            ConnectionDefinition(fromSlotID: "intervention", toSlotID: "outcome", edgeType: .produces),
            ConnectionDefinition(fromSlotID: "outcome", toSlotID: "dataCollection", edgeType: .measuredBy),
            // Sample size
            ConnectionDefinition(fromSlotID: "sampleSize", toSlotID: "population", edgeType: .determines),
            // Rationale
            ConnectionDefinition(fromSlotID: "rationale", toSlotID: "intervention", edgeType: .motivates),
        ]
    )
    
    // MARK: - Cross-Sectional Template
    
    static let crossSectional = StudyDesignTemplate(
        designType: .crossSectional,
        description: "Observes a population at a single point in time to measure the prevalence or association of variables.",
        slots: [
            SlotDefinition(
                id: "rationale",
                label: "Scientific Rationale",
                blockType: .fixed(.rationale),
                isRequired: true,
                helpText: "Why this snapshot study is needed."
            ),
            SlotDefinition(
                id: "population",
                label: "Target Population",
                blockType: .fixed(.targetPopulation),
                isRequired: true,
                helpText: "The population being observed."
            ),
            SlotDefinition(
                id: "outcome",
                label: "Outcome Measure",
                blockType: .fixed(.outcomeMeasure),
                isRequired: true,
                helpText: "What variable or condition is being measured."
            ),
            SlotDefinition(
                id: "dataCollection",
                label: "Data Collection Method",
                blockType: .choice(
                    [.survey, .interview, .biometricSampling],
                    "How will you collect your data?"
                ),
                isRequired: true,
                helpText: "The method used to gather data from participants."
            ),
            SlotDefinition(
                id: "sampleSize",
                label: "Sample Size Justification",
                blockType: .fixed(.sampleSizeJustification),
                isRequired: false,
                helpText: "How the target sample size was determined."
            ),
        ],
        connections: [
            ConnectionDefinition(fromSlotID: "outcome", toSlotID: "population", edgeType: .observedIn),
            ConnectionDefinition(fromSlotID: "outcome", toSlotID: "dataCollection", edgeType: .measuredBy),
            ConnectionDefinition(fromSlotID: "sampleSize", toSlotID: "population", edgeType: .determines),
            ConnectionDefinition(fromSlotID: "rationale", toSlotID: "outcome", edgeType: .motivates),
        ]
    )
    
    // MARK: - Longitudinal Template
    
    static let longitudinal = StudyDesignTemplate(
        designType: .longitudinal,
        description: "Follows participants over time to observe how outcomes change, without assigning an intervention.",
        slots: [
            SlotDefinition(
                id: "rationale",
                label: "Scientific Rationale",
                blockType: .fixed(.rationale),
                isRequired: true,
                helpText: "Why tracking change over time is important for this question."
            ),
            SlotDefinition(
                id: "population",
                label: "Target Population",
                blockType: .fixed(.targetPopulation),
                isRequired: true,
                helpText: "Who will be followed over time."
            ),
            SlotDefinition(
                id: "outcome",
                label: "Primary Outcome",
                blockType: .fixed(.outcomeMeasure),
                isRequired: true,
                helpText: "What is being tracked over the follow-up period."
            ),
            SlotDefinition(
                id: "dataCollection",
                label: "Data Collection Method",
                blockType: .choice(
                    [.survey, .interview, .biometricSampling],
                    "How will you measure the outcome at each time point?"
                ),
                isRequired: true,
                helpText: "The method used at each assessment point."
            ),
            SlotDefinition(
                id: "sampleSize",
                label: "Sample Size Justification",
                blockType: .fixed(.sampleSizeJustification),
                isRequired: true,
                helpText: "Must account for expected attrition over the follow-up period."
            ),
        ],
        connections: [
            ConnectionDefinition(fromSlotID: "outcome", toSlotID: "population", edgeType: .observedIn),
            ConnectionDefinition(fromSlotID: "outcome", toSlotID: "dataCollection", edgeType: .measuredBy),
            ConnectionDefinition(fromSlotID: "sampleSize", toSlotID: "population", edgeType: .determines),
            ConnectionDefinition(fromSlotID: "rationale", toSlotID: "outcome", edgeType: .motivates),
        ]
    )
    
    // MARK: - Stepped-Wedge Template
    
    static let steppedWedge = StudyDesignTemplate(
        designType: .steppedWedge,
        description: "Clusters progressively cross over from control to intervention at staggered time points. All clusters eventually receive the intervention.",
        slots: [
            SlotDefinition(
                id: "rationale",
                label: "Scientific Rationale",
                blockType: .fixed(.rationale),
                isRequired: true,
                helpText: "Why a stepped-wedge design is appropriate (vs parallel RCT)."
            ),
            SlotDefinition(
                id: "population",
                label: "Target Population / Clusters",
                blockType: .fixed(.targetPopulation),
                isRequired: true,
                helpText: "The clusters (hospitals, schools, etc.) and participants within them."
            ),
            SlotDefinition(
                id: "intervention",
                label: "Intervention",
                blockType: .fixed(.intervention),
                isRequired: true,
                helpText: "What each cluster receives when it crosses over."
            ),
            SlotDefinition(
                id: "control",
                label: "Control Condition",
                blockType: .fixed(.controlCondition),
                isRequired: true,
                helpText: "What clusters receive before crossing over."
            ),
            SlotDefinition(
                id: "randomization",
                label: "Randomization Strategy",
                blockType: .fixed(.randomizationStrategy),
                isRequired: true,
                helpText: "How the crossover sequence is determined."
            ),
            SlotDefinition(
                id: "outcome",
                label: "Primary Outcome",
                blockType: .fixed(.outcomeMeasure),
                isRequired: true,
                helpText: "What is measured before and after each cluster crosses over."
            ),
            SlotDefinition(
                id: "dataCollection",
                label: "Data Collection Method",
                blockType: .choice(
                    [.survey, .interview, .biometricSampling],
                    "How will outcome data be collected at each step?"
                ),
                isRequired: true,
                helpText: "Must be repeatable at each assessment period."
            ),
            SlotDefinition(
                id: "sampleSize",
                label: "Sample Size Justification",
                blockType: .fixed(.sampleSizeJustification),
                isRequired: true,
                helpText: "Must account for clustering and the stepped-wedge correlation structure."
            ),
        ],
        connections: [
            ConnectionDefinition(fromSlotID: "population", toSlotID: "intervention", edgeType: .receives),
            ConnectionDefinition(fromSlotID: "population", toSlotID: "control", edgeType: .receives),
            ConnectionDefinition(fromSlotID: "intervention", toSlotID: "control", edgeType: .comparedWith),
            ConnectionDefinition(fromSlotID: "randomization", toSlotID: "population", edgeType: .assignedVia),
            ConnectionDefinition(fromSlotID: "intervention", toSlotID: "outcome", edgeType: .produces),
            ConnectionDefinition(fromSlotID: "outcome", toSlotID: "dataCollection", edgeType: .measuredBy),
            ConnectionDefinition(fromSlotID: "sampleSize", toSlotID: "population", edgeType: .determines),
            ConnectionDefinition(fromSlotID: "rationale", toSlotID: "intervention", edgeType: .motivates),
        ]
    )
    
    // MARK: - Adaptive Template
    
    static let adaptive = StudyDesignTemplate(
        designType: .adaptive,
        description: "Allows pre-planned modifications to the trial based on interim analysis results, while preserving validity.",
        slots: [
            SlotDefinition(
                id: "rationale",
                label: "Scientific Rationale",
                blockType: .fixed(.rationale),
                isRequired: true,
                helpText: "Why an adaptive design is needed and what uncertainty it addresses."
            ),
            SlotDefinition(
                id: "population",
                label: "Target Population",
                blockType: .fixed(.targetPopulation),
                isRequired: true,
                helpText: "Who will be enrolled."
            ),
            SlotDefinition(
                id: "intervention",
                label: "Intervention",
                blockType: .fixed(.intervention),
                isRequired: true,
                helpText: "The treatment being tested."
            ),
            SlotDefinition(
                id: "control",
                label: "Control Condition",
                blockType: .fixed(.controlCondition),
                isRequired: true,
                helpText: "The comparison condition."
            ),
            SlotDefinition(
                id: "randomization",
                label: "Randomization Strategy",
                blockType: .fixed(.randomizationStrategy),
                isRequired: true,
                helpText: "How participants are assigned — may change at adaptation points."
            ),
            SlotDefinition(
                id: "outcome",
                label: "Primary Outcome",
                blockType: .fixed(.outcomeMeasure),
                isRequired: true,
                helpText: "The primary endpoint used for interim decision-making."
            ),
            SlotDefinition(
                id: "dataCollection",
                label: "Data Collection Method",
                blockType: .choice(
                    [.survey, .interview, .biometricSampling],
                    "How will outcome data be collected?"
                ),
                isRequired: true,
                helpText: "The method used to gather outcome data."
            ),
            SlotDefinition(
                id: "sampleSize",
                label: "Sample Size Justification",
                blockType: .fixed(.sampleSizeJustification),
                isRequired: true,
                helpText: "Must account for adaptive re-estimation and Type I error control."
            ),
        ],
        connections: [
            ConnectionDefinition(fromSlotID: "population", toSlotID: "intervention", edgeType: .receives),
            ConnectionDefinition(fromSlotID: "population", toSlotID: "control", edgeType: .receives),
            ConnectionDefinition(fromSlotID: "intervention", toSlotID: "control", edgeType: .comparedWith),
            ConnectionDefinition(fromSlotID: "randomization", toSlotID: "population", edgeType: .assignedVia),
            ConnectionDefinition(fromSlotID: "intervention", toSlotID: "outcome", edgeType: .produces),
            ConnectionDefinition(fromSlotID: "outcome", toSlotID: "dataCollection", edgeType: .measuredBy),
            ConnectionDefinition(fromSlotID: "sampleSize", toSlotID: "population", edgeType: .determines),
            ConnectionDefinition(fromSlotID: "rationale", toSlotID: "intervention", edgeType: .motivates),
        ]
    )
}
