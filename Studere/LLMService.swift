import Foundation
import SwiftUI
import MLXLLM
import MLXLMCommon

// MARK: - LLMModelTier
// Available model tiers, ordered by capability.
// Each tier specifies a HuggingFace model ID from the mlx-community.

enum LLMModelTier: String, CaseIterable, Identifiable {
    case compact    // For 8GB machines with limited headroom
    case standard   // Recommended default — best balance
    case premium    // For 16GB+ machines wanting top quality
    
    var id: String { rawValue }
    
    /// The HuggingFace model repo ID (pre-quantized for MLX).
    var modelID: String {
        switch self {
        case .compact:  return "mlx-community/Qwen3-4B-4bit"
        case .standard: return "mlx-community/Mistral-7B-Instruct-v0.3-4bit"
        case .premium:  return "mlx-community/Qwen2.5-14B-Instruct-4bit"
        }
    }
    
    var displayName: String {
        switch self {
        case .compact:  return "Compact (4B)"
        case .standard: return "Standard (7B)"
        case .premium:  return "Premium (14B)"
        }
    }
    
    var modelDescription: String {
        switch self {
        case .compact:  return "Qwen3 4B — ~2.5 GB download. Fast, works on all Macs."
        case .standard: return "Mistral 7B Instruct — ~4.5 GB download. Best quality-to-speed ratio."
        case .premium:  return "Qwen2.5 14B Instruct — ~8.5 GB download. Near-professional prose. Needs 16 GB+ RAM."
        }
    }
    
    var estimatedRAM: String {
        switch self {
        case .compact:  return "8 GB+"
        case .standard: return "8 GB+"
        case .premium:  return "16 GB+"
        }
    }
    
    /// Manually formats the prompt using the model's expected chat tokens.
    /// This bypasses the Jinja template parser entirely, avoiding TemplateException crashes.
    func formatPrompt(system: String, user: String) -> String {
        switch self {
        case .compact:
            // Qwen3 uses ChatML format
            return """
            <|im_start|>system
            \(system)<|im_end|>
            <|im_start|>user
            \(user)<|im_end|>
            <|im_start|>assistant
            """
            
        case .standard:
            // Mistral Instruct v0.3 format
            return "[INST] \(system)\n\n\(user) [/INST]"
            
        case .premium:
            // Qwen2.5 also uses ChatML format
            return """
            <|im_start|>system
            \(system)<|im_end|>
            <|im_start|>user
            \(user)<|im_end|>
            <|im_start|>assistant
            """
        }
    }
}

// MARK: - LLMService
// Generates a research protocol by processing each SPIRIT section independently.
//
// WHY SECTION-BY-SECTION:
// Even with larger models, feeding the entire serialized study (2000+ tokens)
// and asking for a coherent multi-page restructuring in one shot risks
// content loss and hallucination. By generating each section independently
// with only its relevant data, we get reliable, faithful output.

@Observable
@MainActor
final class LLMService {
    var draftText: String = ""
    var isGenerating: Bool = false
    var currentStatus: String = "Ready"
    
    /// The selected model tier. Persisted in UserDefaults.
    var selectedTier: LLMModelTier {
        didSet {
            UserDefaults.standard.set(selectedTier.rawValue, forKey: "studere.llm.tier")
        }
    }
    
    private var generationTask: Task<Void, Never>?
    
    init() {
        let saved = UserDefaults.standard.string(forKey: "studere.llm.tier") ?? ""
        self.selectedTier = LLMModelTier(rawValue: saved) ?? .standard
    }
    
    // MARK: - Section-by-Section Generation
    
    func generateProtocol(for project: ResearchProject) async {
        cancelGeneration()
        
        generationTask = Task {
            self.isGenerating = true
            self.draftText = ""
            self.currentStatus = "Preparing study data..."
            
            do {
                // 1. Load the selected model (downloads on first use, cached after)
                let modelConfig = ModelConfiguration(id: selectedTier.modelID)
                
                self.currentStatus = "Loading \(selectedTier.displayName) model..."
                
                let modelContext = try await LLMModelFactory.shared.load(
                    configuration: modelConfig
                ) { progress in
                    Task { @MainActor in
                        self.currentStatus = "Downloading model: \(Int(progress.fractionCompleted * 100))%"
                    }
                }
                
                if Task.isCancelled { return }
                
                // 2. Build the document header
                self.draftText = "# \(project.title)\n\n"
                self.draftText += "**Study Design:** \(project.designType?.displayName ?? "Not specified")\n\n"
                self.draftText += "---\n\n"
                
                // 3. Generate each SPIRIT section independently
                let sections = ProtocolSection.allCases
                
                for (index, section) in sections.enumerated() {
                    if Task.isCancelled { break }
                    
                    let sectionNodes = project.scaffoldedNodes.filter {
                        section.sourceNodeTypes.contains($0.nodeType)
                    }
                    
                    let nodesWithData = sectionNodes.filter { !$0.completedFields.isEmpty }
                    if nodesWithData.isEmpty { continue }
                    
                    self.currentStatus = "Writing section \(index + 1)/\(sections.count): \(section.displayName)..."
                    
                    let sectionBundle = buildSectionBundle(
                        section: section,
                        nodes: nodesWithData,
                        projectTitle: project.title,
                        designType: project.designType
                    )
                    
                    let sectionPrompt = buildSectionPrompt(section: section)
                    
                    // Write the section heading BEFORE streaming starts
                    // so the real-time output appears under the correct heading
                    self.draftText += "## \(section.sectionNumber). \(section.displayName)\n\n"
                    
                    // generateSection streams chunks directly to self.draftText
                    try await generateSection(
                        systemPrompt: sectionPrompt,
                        userContent: sectionBundle,
                        modelContext: modelContext
                    )
                    
                    if Task.isCancelled { break }
                    
                    // Add separator after section content
                    self.draftText += "\n\n---\n\n"
                }
                
                if !Task.isCancelled {
                    self.currentStatus = "Draft complete. Please review and endorse."
                }
                
            } catch {
                if !Task.isCancelled {
                    self.draftText += "\n\n> Error generating protocol: \(error.localizedDescription)"
                    self.currentStatus = "Generation failed."
                }
            }
            
            self.isGenerating = false
        }
    }
    
    // MARK: - Single Section Generation
    
    /// Generates prose for one SPIRIT section, streaming directly to draftText.
    /// The local `result` buffer is only used for repetition detection.
    private func generateSection(
        systemPrompt: String,
        userContent: String,
        modelContext: MLXLMCommon.ModelContext
    ) async throws {
        
        // CRITICAL: Use UserInput(prompt:) instead of UserInput(messages:).
        // The messages path triggers the Jinja template parser, which crashes
        // on models with complex chat templates (Qwen3, newer Mistral, etc.).
        // By formatting the prompt manually, we bypass Jinja entirely.
        let formattedPrompt = selectedTier.formatPrompt(
            system: systemPrompt,
            user: userContent
        )
        let userInput = UserInput(prompt: formattedPrompt)
        let lmInput = try await modelContext.processor.prepare(input: userInput)
        
        let parameters = GenerateParameters(
            maxTokens: 512,
            temperature: 0.2,
            repetitionPenalty: 1.2
        )
        
        // Local buffer for repetition detection only
        var result = ""
        
        let stream = try MLXLMCommon.generate(
            input: lmInput,
            parameters: parameters,
            context: modelContext
        )
        
        for await generation in stream {
            if Task.isCancelled { break }
            
            if let chunk = generation.chunk {
                result += chunk
                
                // Stream directly to the UI
                self.draftText += chunk
                
                // Halt if the model enters a repetition loop
                if detectRepetition(in: result) {
                    break
                }
            }
        }
    }
    
    // MARK: - Prompt Construction
    
    private func buildSectionPrompt(section: ProtocolSection) -> String {
        """
        You are a technical writer converting structured research data into protocol prose.
        
        TASK: Write the "\(section.displayName)" section of a research protocol.
        
        RULES:
        1. Use ONLY the data provided. Do not add any information, methods, or references not in the data.
        2. Write in third person, past future tense ("participants will be recruited").
        3. Keep the researcher's exact terminology and specific details (names, doses, instruments).
        4. Where data says [specify ...], output that exact bracketed placeholder.
        5. Write 1-3 concise paragraphs. Do not repeat yourself. Stop when all data points are covered.
        """
    }
    
    private func buildSectionBundle(
        section: ProtocolSection,
        nodes: [ResearchNode],
        projectTitle: String,
        designType: NodeType?
    ) -> String {
        var bundle = "Study: \(projectTitle)\n"
        bundle += "Design: \(designType?.displayName ?? "Not specified")\n"
        bundle += "Section: \(section.displayName)\n\n"
        bundle += "DATA:\n"
        
        for node in nodes {
            bundle += "\n[\(node.title) - \(node.nodeType.displayName)]\n"
            
            let questions = InspectorQuestionBank.questions(for: node.nodeType)
            for question in questions {
                let answer = node.answer(for: question.key)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !answer.isEmpty {
                    bundle += "• \(question.prompt): \(answer)\n"
                }
            }
        }
        
        bundle += "\nEND DATA. Write the section prose now."
        return bundle
    }
    
    // MARK: - Repetition Detection
    
    private func detectRepetition(in text: String) -> Bool {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { $0.split(separator: " ").count >= 8 }
        
        var seen: [String: Int] = [:]
        for sentence in sentences {
            seen[sentence, default: 0] += 1
            if seen[sentence]! >= 3 {
                return true
            }
        }
        return false
    }
    
    // MARK: - Cancellation
    
    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        if isGenerating {
            isGenerating = false
            currentStatus = "Generation cancelled."
        }
    }
}
