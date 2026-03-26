import Foundation

// MARK: - InspectorQuestion
// A single Socratic question presented in the right sidebar inspector (§4.3).
// The `key` is used as the dictionary key in ResearchNode.inspectorData.

struct InspectorQuestion: Identifiable {
    let id: String          // Same as key, for SwiftUI lists
    let key: String         // Storage key in inspectorData, e.g. "outcomeMeasure.instrument"
    let prompt: String      // The question text shown to the user
    let helpText: String?   // Optional explanatory text for beginners
    let isRequired: Bool    // If true, an empty answer triggers a validation error
    
    init(key: String, prompt: String, helpText: String? = nil, isRequired: Bool = true) {
        self.id = key
        self.key = key
        self.prompt = prompt
        self.helpText = helpText
        self.isRequired = isRequired
    }
}

// MARK: - InspectorQuestionBank
// Central registry of all Socratic Inspector questions organized by NodeType.
// This is the pedagogical core of the app — each question teaches the user
// what they need to think about for that component (§4.3).
//
// Questions are intentionally ordered in a logical sequence: broad framing
// questions first, then specifics, then methodological considerations.

struct InspectorQuestionBank {
    
    /// Returns the ordered question sequence for a given node type.
    static func questions(for nodeType: NodeType) -> [InspectorQuestion] {
        switch nodeType {
            
        // MARK: - Entity Blocks
            
        case .targetPopulation:
            return [
                InspectorQuestion(
                    key: "targetPopulation.inclusionCriteria",
                    prompt: "What are the inclusion criteria?",
                    helpText: "Define who is eligible to participate. Be specific about age, diagnosis, setting, or other qualifying characteristics."
                ),
                InspectorQuestion(
                    key: "targetPopulation.exclusionCriteria",
                    prompt: "What are the exclusion criteria?",
                    helpText: "Define who should be excluded and why. Consider safety, confounding factors, and practical constraints."
                ),
                InspectorQuestion(
                    key: "targetPopulation.sampleSize",
                    prompt: "What is the target sample size and how was it determined?",
                    helpText: "State both the number and the reasoning (e.g., power calculation, feasibility, precedent from similar studies)."
                ),
                InspectorQuestion(
                    key: "targetPopulation.recruitmentSetting",
                    prompt: "From what setting or geography will participants be recruited?",
                    helpText: "Describe the recruitment sites, regions, or platforms. This affects generalizability."
                ),
                InspectorQuestion(
                    key: "targetPopulation.ethicalConsiderations",
                    prompt: "Are there ethical considerations specific to this population?",
                    helpText: "Consider vulnerable populations, informed consent capacity, cultural factors, or potential for coercion.",
                    isRequired: false
                ),
            ]
            
        case .controlGroup:
            return [
                InspectorQuestion(
                    key: "controlGroup.type",
                    prompt: "What type of control group will be used?",
                    helpText: "Common types: placebo, active comparator, waitlist, treatment-as-usual, no intervention."
                ),
                InspectorQuestion(
                    key: "controlGroup.justification",
                    prompt: "Why is this type of control appropriate for your research question?",
                    helpText: "Explain why this comparison will allow you to draw the conclusions you need."
                ),
                InspectorQuestion(
                    key: "controlGroup.matching",
                    prompt: "How will the control group be matched or balanced against the intervention group?",
                    helpText: "Consider randomization, stratification, matching on key variables, or propensity scoring."
                ),
                InspectorQuestion(
                    key: "controlGroup.ethicalJustification",
                    prompt: "Is it ethically justified to withhold the intervention from this group?",
                    helpText: "If an effective treatment exists, explain why a control condition is still appropriate.",
                    isRequired: false
                ),
            ]
            
        case .intervention:
            return [
                InspectorQuestion(
                    key: "intervention.description",
                    prompt: "Describe the intervention in enough detail that another researcher could replicate it.",
                    helpText: "Include what is delivered, by whom, how often, for how long, and in what setting."
                ),
                InspectorQuestion(
                    key: "intervention.dosage",
                    prompt: "What is the dose, frequency, and duration of the intervention?",
                    helpText: "Be precise: '60-minute sessions twice weekly for 8 weeks' rather than 'regular sessions'."
                ),
                InspectorQuestion(
                    key: "intervention.deliveryMethod",
                    prompt: "How will the intervention be delivered and by whom?",
                    helpText: "Specify the delivery format (in-person, remote, self-guided) and provider qualifications."
                ),
                InspectorQuestion(
                    key: "intervention.fidelity",
                    prompt: "How will you ensure the intervention is delivered consistently as designed?",
                    helpText: "Consider training protocols, manuals, adherence checklists, or fidelity monitoring.",
                    isRequired: false
                ),
                InspectorQuestion(
                    key: "intervention.adverseEvents",
                    prompt: "What adverse events or risks might participants experience?",
                    helpText: "Consider both anticipated side effects and how they will be monitored and managed.",
                    isRequired: false
                ),
            ]
            
        case .outcomeMeasure:
            return [
                InspectorQuestion(
                    key: "outcomeMeasure.outcomeType",
                    prompt: "Is this outcome continuous or categorical?",
                    helpText: "Continuous outcomes are measured on a scale (e.g., blood pressure). Categorical outcomes fall into groups (e.g., cured/not cured)."
                ),
                InspectorQuestion(
                    key: "outcomeMeasure.instrument",
                    prompt: "What instrument or method will be used to measure it?",
                    helpText: "Name the specific tool, questionnaire, lab test, or assessment procedure."
                ),
                InspectorQuestion(
                    key: "outcomeMeasure.timePoints",
                    prompt: "At what time points will measurement occur?",
                    helpText: "List all planned assessment points (e.g., baseline, 4 weeks, 12 weeks, 6 months)."
                ),
                InspectorQuestion(
                    key: "outcomeMeasure.mcid",
                    prompt: "What is the minimally clinically important difference?",
                    helpText: "The smallest change in this outcome that would be meaningful to patients or clinicians."
                ),
                InspectorQuestion(
                    key: "outcomeMeasure.validityConcerns",
                    prompt: "Are there known validity or reliability concerns with this measure?",
                    helpText: "Consider cultural validation, test-retest reliability, sensitivity to change, or ceiling/floor effects.",
                    isRequired: false
                ),
            ]
            
        // MARK: - Design Blocks
            
        case .rct:
            return [
                InspectorQuestion(
                    key: "rct.arms",
                    prompt: "How many arms will this trial have and what does each arm receive?",
                    helpText: "Describe each treatment group. A simple RCT has two arms; multi-arm trials compare several interventions."
                ),
                InspectorQuestion(
                    key: "rct.allocationRatio",
                    prompt: "What is the allocation ratio between arms?",
                    helpText: "Common ratios: 1:1 (equal), 2:1 (more in treatment). Unequal ratios affect power calculations."
                ),
                InspectorQuestion(
                    key: "rct.primaryEndpoint",
                    prompt: "What is the primary endpoint and when is it assessed?",
                    helpText: "The single most important outcome that will determine whether the intervention works."
                ),
                InspectorQuestion(
                    key: "rct.analysisPlan",
                    prompt: "What is the planned primary analysis approach?",
                    helpText: "Describe the statistical method (e.g., intention-to-treat with mixed-effects model)."
                ),
            ]
            
        case .crossSectional:
            return [
                InspectorQuestion(
                    key: "crossSectional.timeframe",
                    prompt: "Over what time period will data be collected?",
                    helpText: "Cross-sectional studies capture a snapshot. Define the data collection window."
                ),
                InspectorQuestion(
                    key: "crossSectional.samplingStrategy",
                    prompt: "What sampling strategy will be used?",
                    helpText: "Options include random, convenience, stratified, or cluster sampling. Each has trade-offs for generalizability."
                ),
                InspectorQuestion(
                    key: "crossSectional.variables",
                    prompt: "What are the main variables of interest and how are they related?",
                    helpText: "Identify exposure/predictor variables and outcome variables. Note that cross-sectional designs cannot establish causation."
                ),
                InspectorQuestion(
                    key: "crossSectional.confounders",
                    prompt: "What potential confounders will you measure and control for?",
                    helpText: "List variables that could influence both the exposure and outcome.",
                    isRequired: false
                ),
            ]
            
        case .longitudinal:
            return [
                InspectorQuestion(
                    key: "longitudinal.followUpDuration",
                    prompt: "What is the total follow-up duration?",
                    helpText: "How long will participants be tracked from enrollment to final assessment?"
                ),
                InspectorQuestion(
                    key: "longitudinal.assessmentSchedule",
                    prompt: "What is the assessment schedule?",
                    helpText: "List all time points at which data will be collected."
                ),
                InspectorQuestion(
                    key: "longitudinal.attritionPlan",
                    prompt: "How will you handle participant attrition over time?",
                    helpText: "Describe strategies for retention and statistical approaches for handling missing data."
                ),
                InspectorQuestion(
                    key: "longitudinal.changeHypothesis",
                    prompt: "What pattern of change over time do you expect to observe?",
                    helpText: "Linear trend? Threshold effect? Plateau? Your hypothesis shapes the analytical approach.",
                    isRequired: false
                ),
            ]
            
        case .steppedWedge:
            return [
                InspectorQuestion(
                    key: "steppedWedge.clusters",
                    prompt: "How many clusters will participate and what defines a cluster?",
                    helpText: "Clusters are the units that cross over (e.g., hospitals, schools, clinics)."
                ),
                InspectorQuestion(
                    key: "steppedWedge.steps",
                    prompt: "How many steps (crossover points) are planned?",
                    helpText: "At each step, one or more clusters switch from control to intervention."
                ),
                InspectorQuestion(
                    key: "steppedWedge.stepDuration",
                    prompt: "What is the duration of each step?",
                    helpText: "All steps are typically the same length. Consider the time needed for the intervention to take effect."
                ),
                InspectorQuestion(
                    key: "steppedWedge.justification",
                    prompt: "Why is a stepped-wedge design appropriate rather than a parallel RCT?",
                    helpText: "Common reasons: logistical (can't implement everywhere at once), ethical (all clusters eventually receive intervention), political acceptability."
                ),
            ]
            
        case .adaptive:
            return [
                InspectorQuestion(
                    key: "adaptive.adaptationType",
                    prompt: "What type of adaptation is planned?",
                    helpText: "Options include sample size re-estimation, dose finding, treatment arm dropping, adaptive randomization, or enrichment."
                ),
                InspectorQuestion(
                    key: "adaptive.decisionRules",
                    prompt: "What pre-specified rules govern each adaptation?",
                    helpText: "Define the criteria and thresholds that trigger each adaptation. These must be specified before the trial begins."
                ),
                InspectorQuestion(
                    key: "adaptive.interimAnalyses",
                    prompt: "When will interim analyses occur?",
                    helpText: "Specify the timing and the statistical methods for interim looks (e.g., group sequential boundaries)."
                ),
                InspectorQuestion(
                    key: "adaptive.typeIControl",
                    prompt: "How will the overall Type I error rate be controlled?",
                    helpText: "Multiple looks at the data inflate false positive risk. Describe the alpha-spending approach.",
                    isRequired: false
                ),
            ]
            
        // MARK: - Method Blocks
            
        case .survey:
            return [
                InspectorQuestion(
                    key: "survey.instrument",
                    prompt: "Is this a validated instrument or a custom survey? If validated, which one?",
                    helpText: "Using validated instruments strengthens your study. If custom, you may need to pilot and validate."
                ),
                InspectorQuestion(
                    key: "survey.mode",
                    prompt: "How will the survey be administered?",
                    helpText: "Options: paper, online, phone, in-person interview. Mode can affect response rates and data quality."
                ),
                InspectorQuestion(
                    key: "survey.timing",
                    prompt: "When and how often will participants complete this survey?",
                    helpText: "Align with your outcome measurement time points."
                ),
                InspectorQuestion(
                    key: "survey.missingData",
                    prompt: "How will you handle incomplete survey responses?",
                    helpText: "Consider thresholds for valid responses (e.g., 80% item completion) and imputation strategies.",
                    isRequired: false
                ),
            ]
            
        case .interview:
            return [
                InspectorQuestion(
                    key: "interview.structure",
                    prompt: "Is this structured, semi-structured, or unstructured?",
                    helpText: "Structured uses fixed questions; semi-structured has a guide but allows follow-up; unstructured is open-ended."
                ),
                InspectorQuestion(
                    key: "interview.guide",
                    prompt: "Describe the topic guide or key domains to be explored.",
                    helpText: "What are the main areas you want to cover? Even unstructured interviews benefit from a topic framework."
                ),
                InspectorQuestion(
                    key: "interview.recording",
                    prompt: "How will interviews be recorded and transcribed?",
                    helpText: "Audio recording with verbatim transcription is standard. Consider who will transcribe and quality checks."
                ),
                InspectorQuestion(
                    key: "interview.analysisApproach",
                    prompt: "What analytical framework will be applied to the interview data?",
                    helpText: "Common approaches: thematic analysis, grounded theory, framework analysis, IPA.",
                    isRequired: false
                ),
            ]
            
        case .biometricSampling:
            return [
                InspectorQuestion(
                    key: "biometric.sampleType",
                    prompt: "What biological samples will be collected?",
                    helpText: "Specify the sample type (blood, saliva, tissue, urine, etc.) and the biomarkers of interest."
                ),
                InspectorQuestion(
                    key: "biometric.collectionProtocol",
                    prompt: "Describe the collection protocol including timing, preparation, and handling.",
                    helpText: "Include fasting requirements, time of day, processing steps, and storage conditions."
                ),
                InspectorQuestion(
                    key: "biometric.laboratoryMethods",
                    prompt: "What laboratory methods or assays will be used for analysis?",
                    helpText: "Name the specific assay, platform, or analytical method. Include sensitivity and reference ranges."
                ),
                InspectorQuestion(
                    key: "biometric.qualityControl",
                    prompt: "What quality control measures are in place?",
                    helpText: "Consider duplicate samples, calibration standards, inter-lab validation, and chain of custody.",
                    isRequired: false
                ),
            ]
            
        // MARK: - Supporting Blocks
            
        case .randomizationStrategy:
            return [
                InspectorQuestion(
                    key: "randomization.method",
                    prompt: "What randomization method will be used?",
                    helpText: "Options: simple, block, stratified, cluster, or adaptive randomization."
                ),
                InspectorQuestion(
                    key: "randomization.implementation",
                    prompt: "How will randomization be implemented and by whom?",
                    helpText: "Describe the tool (e.g., REDCap, sealed envelopes) and who will perform allocation."
                ),
                InspectorQuestion(
                    key: "randomization.stratificationFactors",
                    prompt: "Will randomization be stratified? If so, on what factors?",
                    helpText: "Stratification ensures balance on key prognostic variables (e.g., age group, disease severity).",
                    isRequired: false
                ),
            ]
            
        case .blindingProtocol:
            return [
                InspectorQuestion(
                    key: "blinding.level",
                    prompt: "What level of blinding will be used?",
                    helpText: "Options: open-label (none), single-blind (participant), double-blind (participant + assessor), triple-blind (+ analyst)."
                ),
                InspectorQuestion(
                    key: "blinding.method",
                    prompt: "How will blinding be maintained?",
                    helpText: "Describe matching placebos, concealment procedures, or other methods to prevent unblinding."
                ),
                InspectorQuestion(
                    key: "blinding.unbindingRules",
                    prompt: "Under what circumstances would unblinding be permitted?",
                    helpText: "Typically for safety reasons. Define who can authorize unblinding and how it will be documented.",
                    isRequired: false
                ),
            ]
            
        case .controlCondition:
            return [
                InspectorQuestion(
                    key: "controlCondition.description",
                    prompt: "Describe exactly what the control condition involves.",
                    helpText: "Be as specific about the control as you are about the intervention. 'Standard care' must be defined."
                ),
                InspectorQuestion(
                    key: "controlCondition.justification",
                    prompt: "Why was this control condition chosen?",
                    helpText: "Explain how this comparison allows you to isolate the effect of your intervention."
                ),
            ]
            
        case .sampleSizeJustification:
            return [
                InspectorQuestion(
                    key: "sampleSize.targetN",
                    prompt: "What is the target sample size?",
                    helpText: "State the number per group and total."
                ),
                InspectorQuestion(
                    key: "sampleSize.calculation",
                    prompt: "How was this sample size calculated?",
                    helpText: "Include the effect size, alpha level, power, and any adjustment for attrition or clustering."
                ),
                InspectorQuestion(
                    key: "sampleSize.effectSizeSource",
                    prompt: "Where does the assumed effect size come from?",
                    helpText: "Cite pilot data, prior literature, or clinical judgment. This is often the most scrutinized assumption."
                ),
                InspectorQuestion(
                    key: "sampleSize.attritionAdjustment",
                    prompt: "Has the sample size been adjusted for expected attrition?",
                    helpText: "State the expected dropout rate and how the target N accounts for it.",
                    isRequired: false
                ),
            ]
            
        case .rationale:
            return [
                InspectorQuestion(
                    key: "rationale.background",
                    prompt: "What is the scientific background that motivates this study?",
                    helpText: "Summarize what is currently known and the gap your study addresses."
                ),
                InspectorQuestion(
                    key: "rationale.gap",
                    prompt: "What specific knowledge gap does this study aim to fill?",
                    helpText: "State clearly what is unknown or uncertain that your study will help resolve."
                ),
                InspectorQuestion(
                    key: "rationale.significance",
                    prompt: "Why is filling this gap important?",
                    helpText: "Consider clinical, public health, theoretical, or policy significance.",
                    isRequired: false
                ),
            ]
        }
    }
    
    /// Returns just the keys for a given node type (used for completeness checking).
    static func requiredKeys(for nodeType: NodeType) -> [String] {
        questions(for: nodeType)
            .filter { $0.isRequired }
            .map { $0.key }
    }
    
    /// Returns all keys for a given node type.
    static func allKeys(for nodeType: NodeType) -> [String] {
        questions(for: nodeType).map { $0.key }
    }
}
