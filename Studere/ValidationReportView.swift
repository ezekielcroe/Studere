import SwiftUI

// MARK: - ValidationReportView
// Displays the results of a validation check as a navigable sheet.
// Researchers can tap any missing field to jump straight to that
// component in the inspector.

struct ValidationReportView: View {
    @Environment(\.dismiss) private var dismiss
    
    let report: ValidationService.Report
    /// Callback to navigate to a specific node in the inspector.
    var onNavigateToNode: ((ResearchNode) -> Void)?
    
    var body: some View {
        NavigationStack {
            List {
                overviewSection
                
                if report.isValid {
                    readySection
                } else {
                    incompleteSection
                }
                
                completedSection
            }
            .navigationTitle("Validation Report")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 500)
        #endif
    }
    
    // MARK: - Overview
    
    private var overviewSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: report.isValid ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundStyle(report.isValid ? .green : .orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(report.isValid ? "Ready for protocol drafting" : "Some fields need attention")
                            .font(.headline)
                        
                        Text("\(report.totalFilled) of \(report.totalRequired) required fields completed")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                ProgressView(value: report.overallProgress)
                    .tint(report.isValid ? .green : .orange)
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Ready
    
    private var readySection: some View {
        Section {
            Label(
                "All required fields are filled. You can now draft your protocol.",
                systemImage: "sparkles"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Incomplete Nodes
    
    private var incompleteSection: some View {
        Section {
            ForEach(report.incompleteNodes) { nodeReport in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: nodeReport.node.nodeType.iconName)
                            .font(.caption)
                            .frame(width: 24, height: 24)
                            .foregroundStyle(.white)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(categoryColor(nodeReport.node.category))
                            )
                        
                        Text(nodeReport.node.title)
                            .font(.subheadline.weight(.semibold))
                        
                        Spacer()
                        
                        Text("\(nodeReport.filled)/\(nodeReport.total)")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.15))
                            )
                            .foregroundStyle(.orange)
                    }
                    
                    ForEach(nodeReport.missingFields) { field in
                        Button {
                            dismiss()
                            // Small delay so the sheet dismisses before the inspector opens
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onNavigateToNode?(field.node)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "circle")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.orange)
                                
                                Text(field.questionPrompt)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Needs attention")
        } footer: {
            Text("Tap any missing field to open its inspector.")
                .font(.caption)
        }
    }
    
    // MARK: - Completed Nodes
    
    private var completedSection: some View {
        let completed = report.nodeReports.filter(\.isComplete)
        return Group {
            if !completed.isEmpty {
                Section("Completed") {
                    ForEach(completed) { nodeReport in
                        HStack {
                            Image(systemName: nodeReport.node.nodeType.iconName)
                                .font(.caption)
                                .frame(width: 24, height: 24)
                                .foregroundStyle(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(categoryColor(nodeReport.node.category))
                                )
                            
                            Text(nodeReport.node.title)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
        }
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
