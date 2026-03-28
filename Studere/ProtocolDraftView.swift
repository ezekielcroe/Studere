import SwiftUI
import UniformTypeIdentifiers
import SwiftData

// MARK: - ProtocolDraftView
// Split-pane view: left shows the structured data input reference,
// right shows the LLM-generated protocol draft with a live editor.
//
// Toolbar:
//   LEFT:   Close
//   RIGHT:  Endorse & Export (saves draft text, updates status, triggers file export)

struct ProtocolDraftView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let project: ResearchProject
    
    @State private var llmService = LLMService()
    
    // Export state
    @State private var showingExporter = false
    @State private var draftDocument: ProtocolDraftDocument?
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                referencePane
                Divider()
                editorPane
            }
            .navigationTitle("Protocol Draft: \(project.title)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        llmService.cancelGeneration()
                        dismiss()
                    }
                }
                
                // Model picker — disabled during generation
                ToolbarItem(placement: .automatic) {
                    Picker("Model", selection: $llmService.selectedTier) {
                        ForEach(LLMModelTier.allCases) { tier in
                            Text(tier.displayName).tag(tier)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(llmService.isGenerating)
                    .help("Choose the AI model for protocol generation")
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        endorseAndExport()
                    } label: {
                        Label("Endorse & Export", systemImage: "checkmark.seal")
                    }
                    .disabled(llmService.isGenerating || llmService.draftText.isEmpty)
                    .help("Endorse this draft and export as a file")
                }
            }
            .fileExporter(
                isPresented: $showingExporter,
                document: draftDocument,
                contentType: .plainText,
                defaultFilename: "\(project.title) - Protocol.md"
            ) { result in
                switch result {
                case .success(let url):
                    print("Protocol exported to: \(url.path)")
                case .failure(let error):
                    print("Export failed: \(error.localizedDescription)")
                }
                dismiss()
            }
            .task {
                await llmService.generateProtocol(for: project)
            }
        }
        #if os(macOS)
        .frame(minWidth: 900, minHeight: 600)
        #endif
    }
    
    // MARK: - Reference Pane (Left)
    
    private var referencePane: some View {
        List {
            Section("Structured Data Input") {
                Text("The AI is generating prose based strictly on the data you entered in the Socratic Inspector. You remain the author of this study.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
                
                ForEach(project.scaffoldedNodes) { node in
                    VStack(alignment: .leading) {
                        HStack(spacing: 8) {
                            Image(systemName: node.nodeType.iconName)
                                .font(.caption)
                                .frame(width: 22, height: 22)
                                .foregroundStyle(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(categoryColor(node.category))
                                )
                            
                            Text(node.title)
                                .font(.subheadline.weight(.semibold))
                        }
                        
                        Text("\(node.completedFields.count) fields completed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(width: 300)
    }
    
    // MARK: - Editor Pane (Right)
    
    private var editorPane: some View {
        VStack(spacing: 0) {
            // Status bar
            HStack {
                if llmService.isGenerating {
                    ProgressView()
                        .scaleEffect(0.7)
                        .padding(.trailing, 4)
                }
                
                Text(llmService.currentStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if llmService.isGenerating {
                    Button("Stop") {
                        llmService.cancelGeneration()
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } else if !llmService.draftText.isEmpty {
                    Button("Regenerate") {
                        Task {
                            await llmService.generateProtocol(for: project)
                        }
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Re-draft with current model selection")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(
                llmService.isGenerating
                    ? Color.accentColor.opacity(0.08)
                    : Color.green.opacity(0.08)
            )
            
            Divider()
            
            // Editable draft text
            TextEditor(text: $llmService.draftText)
                .font(.body)
                .padding()
                .scrollContentBackground(.hidden)
                .background(Color(NSColor.textBackgroundColor))
        }
    }
    
    // MARK: - Endorse & Export
    
    private func endorseAndExport() {
        // 1. Update project status to endorsed
        project.status = .protocolDrafted
        project.touch()
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save endorsed status: \(error.localizedDescription)")
        }
        
        // 2. Create the export document from the draft text
        draftDocument = ProtocolDraftDocument(content: llmService.draftText)
        
        // 3. Trigger the file exporter
        showingExporter = true
    }
    
    // MARK: - Helpers
    
    private func categoryColor(_ category: NodeCategory) -> Color {
        switch category {
        case .design:       return .blue
        case .entity:       return .green
        case .method:       return .orange
        case .supporting:   return .purple
        }
    }
}


// MARK: - ProtocolDraftDocument
// A simple FileDocument wrapper for the LLM-generated draft text.
// This allows the standard .fileExporter to save the endorsed protocol.

struct ProtocolDraftDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    
    var content: String
    
    init(content: String) {
        self.content = content
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            content = String(data: data, encoding: .utf8) ?? ""
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(content.utf8))
    }
}
