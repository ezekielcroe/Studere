//
//  ExportFormat.swift
//  Studere
//
//  Created by Zhi Zheng Yeo on 27/3/26.
//


import SwiftUI
import UniformTypeIdentifiers

// MARK: - Export Formats
enum ExportFormat: String, CaseIterable, Identifiable {
    case markdown = "Markdown (.md)"
    case csv = "CSV (.csv)"
    case word = "Word / Rich Text (.rtf)"
    
    var id: String { self.rawValue }
    
    var utType: UTType {
        switch self {
        case .markdown: return .plainText
        case .csv: return .commaSeparatedText
        case .word: return .rtf
        }
    }
    
    var defaultExtension: String {
        switch self {
        case .markdown: return "md"
        case .csv: return "csv"
        case .word: return "rtf"
        }
    }
}

// MARK: - StudyExportDocument
struct StudyExportDocument: FileDocument {
    /// Pre-generated content snapshot (avoids holding a non-Sendable @Model reference).
    private let markdownContent: String
    private let csvContent: String
    let format: ExportFormat
    
    static var readableContentTypes: [UTType] { [.plainText, .commaSeparatedText, .rtf] }
    
    init(project: ResearchProject, format: ExportFormat) {
        self.format = format
        self.markdownContent = Self.generateMarkdown(from: project)
        self.csvContent = Self.generateCSV(from: project)
    }
    
    init(configuration: ReadConfiguration) throws {
        // We only support writing/exporting, not reading.
        throw CocoaError(.fileReadUnsupportedScheme)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data: Data
        
        switch format {
        case .markdown:
            data = Data(markdownContent.utf8)
            
        case .csv:
            data = Data(csvContent.utf8)
            
        case .word:
            // Native conversion from Markdown -> NSAttributedString -> Rich Text (RTF)
            if let attrString = try? NSAttributedString(markdown: markdownContent),
               let rtfData = try? attrString.data(from: NSRange(location: 0, length: attrString.length),
                                                  documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]) {
                data = rtfData
            } else {
                // Fallback to plain text if RTF synthesis fails
                data = Data(markdownContent.utf8)
            }
        }
        
        return FileWrapper(regularFileWithContents: data)
    }
    
    // MARK: - Generators
    
    private static func generateMarkdown(from project: ResearchProject) -> String {
        var md = "# \(project.title)\n\n"
        md += "**Study Design:** \(project.designType?.displayName ?? "Not Specified")  \n"
        md += "**Exported On:** \(Date().formatted(date: .abbreviated, time: .shortened))\n\n"
        md += "---\n\n"
        
        // Group by SPIRIT Guidelines using your ProtocolSection enum
        for section in ProtocolSection.allCases {
            let sectionNodes = project.scaffoldedNodes.filter { section.sourceNodeTypes.contains($0.nodeType) }
            
            // Only render the section if the user has actually filled out data in it
            let nodesWithData = sectionNodes.filter { !$0.completedFields.isEmpty }
            if nodesWithData.isEmpty { continue }
            
            md += "## \(section.sectionNumber). \(section.displayName)\n\n"
            
            for node in nodesWithData {
                md += "### \(node.title)\n\n"
                
                let questions = InspectorQuestionBank.questions(for: node.nodeType)
                for q in questions {
                    let answer = node.answer(for: q.key).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !answer.isEmpty {
                        md += "**\(q.prompt)** \n\(answer)\n\n"
                    }
                }
            }
        }
        
        return md
    }
    
    private static func generateCSV(from project: ResearchProject) -> String {
        var csv = "Protocol Section,Component,Question,Answer\n"
        
        // CSV fields must be escaped to handle newlines and commas inside user answers
        func escape(_ str: String) -> String {
            let escaped = str.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        
        for section in ProtocolSection.allCases {
            let sectionNodes = project.scaffoldedNodes.filter { section.sourceNodeTypes.contains($0.nodeType) }
            
            for node in sectionNodes {
                let questions = InspectorQuestionBank.questions(for: node.nodeType)
                for q in questions {
                    let answer = node.answer(for: q.key).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !answer.isEmpty {
                        csv += "\(escape(section.displayName)),\(escape(node.title)),\(escape(q.prompt)),\(escape(answer))\n"
                    }
                }
            }
        }
        return csv
    }
}
