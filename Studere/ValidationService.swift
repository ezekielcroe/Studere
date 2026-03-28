import Foundation

// MARK: - ValidationService
// Runs a completeness audit on a ResearchProject and returns a
// structured report the UI can display. This is the gate that
// determines whether the researcher is ready for protocol drafting.

struct ValidationService {
    
    /// A single missing-field entry in the report.
    struct MissingField: Identifiable {
        let id = UUID()
        let questionKey: String
        let questionPrompt: String
        let node: ResearchNode
    }
    
    /// Per-node summary of what's filled and what's missing.
    struct NodeReport: Identifiable {
        let id: UUID
        let node: ResearchNode
        let filled: Int
        let total: Int
        let missingFields: [MissingField]
        
        var isComplete: Bool { total == 0 || filled == total }
        var progressFraction: Double {
            guard total > 0 else { return 1.0 }
            return Double(filled) / Double(total)
        }
    }
    
    /// The full validation report for a project.
    struct Report {
        let projectTitle: String
        let nodeReports: [NodeReport]
        let totalFilled: Int
        let totalRequired: Int
        
        var isValid: Bool { totalFilled == totalRequired }
        var overallProgress: Double {
            guard totalRequired > 0 else { return 1.0 }
            return Double(totalFilled) / Double(totalRequired)
        }
        
        /// Only nodes that still have missing required fields.
        var incompleteNodes: [NodeReport] {
            nodeReports.filter { !$0.isComplete }
        }
        
        /// All missing fields across the entire project, flattened.
        var allMissingFields: [MissingField] {
            nodeReports.flatMap(\.missingFields)
        }
    }
    
    // MARK: - Run Validation
    
    /// Validates the project and returns a structured report.
    static func validate(_ project: ResearchProject) -> Report {
        var nodeReports: [NodeReport] = []
        var totalFilled = 0
        var totalRequired = 0
        
        for node in project.scaffoldedNodes {
            let questions = InspectorQuestionBank.questions(for: node.nodeType)
            let requiredQuestions = questions.filter(\.isRequired)
            
            var missingFields: [MissingField] = []
            var filledCount = 0
            
            for question in requiredQuestions {
                let answer = node.answer(for: question.key)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if answer.isEmpty {
                    missingFields.append(MissingField(
                        questionKey: question.key,
                        questionPrompt: question.prompt,
                        node: node
                    ))
                } else {
                    filledCount += 1
                }
            }
            
            totalFilled += filledCount
            totalRequired += requiredQuestions.count
            
            nodeReports.append(NodeReport(
                id: node.id,
                node: node,
                filled: filledCount,
                total: requiredQuestions.count,
                missingFields: missingFields
            ))
        }
        
        return Report(
            projectTitle: project.title,
            nodeReports: nodeReports,
            totalFilled: totalFilled,
            totalRequired: totalRequired
        )
    }
}
