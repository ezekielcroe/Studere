//
//  sections.swift
//  Studere
//
//  Created by Zhi Zheng Yeo on 27/3/26.
//


import Foundation

// MARK: - ProtocolSerializer
// Responsible for transforming the visual SwiftData graph into a structured,
// text-based bundle organized by SPIRIT protocol sections.
// This is the strict input that will be fed to the LLM.

struct ProtocolSerializer {
    
    /// Serializes a ResearchProject into a structured text bundle for LLM ingestion.
    static func serialize(_ project: ResearchProject) -> String {
        var bundle = "# Study Protocol Data Bundle\n"
        bundle += "Project Title: \(project.title)\n"
        bundle += "Study Design: \(project.designType?.displayName ?? "Not Specified")\n\n"
        bundle += "---\n\n"
        
        // 1. Iterate through the SPIRIT sections in canonical order
        for section in ProtocolSection.allCases {
            
            // 2. Find all scaffolded nodes that belong in this section
            let sectionNodes = project.scaffoldedNodes.filter { section.sourceNodeTypes.contains($0.nodeType) }
            
            if sectionNodes.isEmpty { continue }
            
            bundle += "## \(section.sectionNumber). \(section.displayName)\n\n"
            
            // 3. Extract the inspector data for each node
            for node in sectionNodes {
                bundle += "### Component: \(node.title) (\(node.nodeType.displayName))\n"
                
                let questions = InspectorQuestionBank.questions(for: node.nodeType)
                for question in questions {
                    let answer = node.answer(for: question.key).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    bundle += "**Question:** \(question.prompt)\n"
                    bundle += "**Researcher's Answer:**\n"
                    
                    if !answer.isEmpty {
                        // User provided an answer
                        bundle += "\(answer)\n\n"
                    } else {
                        // 4. Placeholder Generation for Missing Data
                        if question.isRequired {
                            // Extract a clean placeholder hint from the prompt (removing question marks)
                            let cleanPrompt = question.prompt.lowercased().replacingOccurrences(of: "?", with: "")
                            bundle += "[specify \(cleanPrompt)]\n\n"
                        } else {
                            bundle += "*(Optional field left intentionally blank)*\n\n"
                        }
                    }
                }
            }
            bundle += "---\n\n"
        }
        
        return bundle
    }
    
    /// A quick diagnostic method to print the bundle to the console during development
    static func printDiagnosticBundle(for project: ResearchProject) {
        let text = serialize(project)
        print("\n==================================================")
        print("BEGIN PROTOCOL SERIALIZATION DIAGNOSTIC")
        print("==================================================\n")
        print(text)
        print("\n==================================================")
        print("END PROTOCOL SERIALIZATION DIAGNOSTIC")
        print("==================================================\n")
    }
}