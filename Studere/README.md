# Studere

**Structured study design and protocol drafting for researchers — entirely on your Mac.**

Studere is a local-first macOS app that guides researchers through designing their study methodology and then transcribes their structured input into a written research protocol using on-device AI. No cloud. No accounts. No data leaves your machine.

---

## What It Does

Research protocol writing is hard — not because writing is hard, but because the *methodological thinking* behind a protocol has dozens of moving parts that need to be internally consistent. Studere breaks that problem into three phases:

### 1. Scaffold Your Study Design

Choose a study design type — Randomized Controlled Trial, Cross-Sectional, Longitudinal, Stepped-Wedge, or Adaptive — and Studere generates the full skeleton of components your study requires: population, intervention, control conditions, outcome measures, data collection methods, randomization, blinding, sample size justification, and scientific rationale.

Components are pre-connected with methodological relationships (e.g., "population *receives* intervention," "outcome *measured by* survey") so the logical structure of your study is visible from the start.

### 2. Fill In the Socratic Inspector

Each component opens an inspector panel with guided questions that walk you through what you need to define. Questions are sequenced from broad framing to specific methodological detail, with help text that explains *why* each question matters.

A validation system tracks your progress and tells you exactly which fields still need attention before you can proceed to drafting.

### 3. Draft Your Protocol with Local AI

Once validation passes, Studere feeds your structured data to an on-device language model (running via Apple's MLX framework) and generates protocol prose section by section, following SPIRIT guideline structure. The AI uses *only* the data you entered — no hallucinated methods, no invented references, no fabricated details.

You review, edit, endorse, and export. You remain the author.

---

## Key Features

- **Template-driven scaffolding** — Study designs come pre-loaded with the components and connections that design type requires. You can't accidentally forget the control condition in an RCT.
- **Socratic Inspector** — Guided questions with help text for every component type. Teaches junior researchers what to think about; saves senior researchers from forgetting to document what they already know.
- **Validation gate** — Tracks completion of all required fields across every component. Protocol drafting is blocked until your study design is complete.
- **Graph visualization** — See your entire study design as a directed graph with labeled methodological relationships between components.
- **Section-by-section AI drafting** — Each SPIRIT protocol section is generated independently with only its relevant data, producing faithful and focused prose from small local models.
- **Three model tiers** — Choose based on your hardware:
  - **Compact (4B)** — Qwen3 4B, ~2.5 GB. Works on all Apple Silicon Macs.
  - **Standard (7B)** — Mistral 7B Instruct, ~4.5 GB. Best quality-to-speed balance.
  - **Premium (14B)** — Qwen2.5 14B Instruct, ~8.5 GB. Near-professional prose. Needs 16 GB+ RAM.
- **Fully local** — SwiftData persistence, on-device MLX inference. Nothing is transmitted externally.
- **Export options** — Export raw structured data (Markdown, JSON) or the AI-drafted protocol as a text document.

---

## Supported Study Designs

| Design | Description |
|---|---|
| Randomized Controlled Trial | Randomly assigns participants to intervention vs. control groups |
| Cross-Sectional | Observes a population at a single point in time |
| Longitudinal | Follows participants over time without assigning an intervention |
| Stepped-Wedge | Clusters progressively cross over from control to intervention |
| Adaptive | Pre-planned modifications to the trial based on interim results |

Each template includes the appropriate set of entity blocks (population, intervention, outcomes), method blocks (survey, interview, biometric sampling), and supporting blocks (randomization, blinding, sample size, rationale) with pre-wired connections.

---

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon (M1 or later) — required for MLX inference
- 8 GB RAM minimum (16 GB+ recommended for the Premium model tier)
- Xcode 15.0+ to build from source

### Dependencies

- [mlx-swift-examples (MLXLLM)](https://github.com/ml-explore/mlx-swift-examples) — On-device language model inference via Apple's MLX framework
- SwiftData — Local persistence
- SwiftUI — Interface

---

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/Studere.git
   cd Studere
   ```

2. Open `Studere.xcodeproj` in Xcode.

3. Resolve Swift Package Manager dependencies (Xcode will fetch MLXLLM automatically).

4. Build and run on your Mac (Apple Silicon required).

5. Create a new study, choose a design type, and start filling in the Socratic Inspector.

> **Note:** The first time you draft a protocol, Studere will download the selected language model from HuggingFace (~2.5–8.5 GB depending on tier). Subsequent runs use the cached model.

---

## Project Structure

```
Studere/
├── StudereApp.swift                 # App entry point and SwiftData container
├── ContentView.swift                # Navigation split view (sidebar + detail)
│
├── Models
│   ├── ResearchProject.swift        # Top-level project container
│   ├── ResearchNode.swift           # Individual study component (node in the graph)
│   ├── ResearchEdge.swift           # Directed relationship between nodes
│   ├── NodeType.swift               # Component type taxonomy (design/entity/method/supporting)
│   └── EdgeType.swift               # Relationship type taxonomy (receives/measuredBy/produces/...)
│
├── Templates & Scaffolding
│   ├── StudyDesignTemplate.swift    # Declarative template definitions for each design type
│   └── ScaffoldBuilder.swift        # Instantiates templates into SwiftData graph
│
├── Inspector & Validation
│   ├── InspectorQuestionBank.swift  # All Socratic questions organized by node type
│   ├── NodeInspectorSheet.swift     # Right-panel inspector UI
│   └── ValidationService.swift      # Completeness audit and structured reporting
│
├── Protocol Generation
│   ├── ProtocolSection.swift        # SPIRIT section definitions and node-type mappings
│   ├── ProtocolSerializer.swift     # Graph → structured text bundle for LLM
│   └── LLMService.swift             # On-device inference with streaming and repetition detection
│
├── Views
│   ├── ProjectListView.swift        # Sidebar project list
│   ├── ProjectDetailView.swift      # Main detail view with component list
│   ├── StudySetupView.swift         # Design type selection wizard
│   ├── StudyGraphView.swift         # Visual graph representation
│   ├── ProtocolDraftView.swift      # Split-pane drafting view (reference + editor)
│   ├── ValidationReportView.swift   # Completeness report with navigation
│   ├── AddComponentSheet.swift      # Manual component addition
│   ├── ComponentRowView.swift       # Single component in the list view
│   └── ConnectionRowView.swift      # Edge display in reference lists
│
└── Utilities
    ├── ProjectDuplicator.swift      # Deep copy of projects with graph rewiring
    └── StudyExport.swift            # File export (Markdown, JSON)
```

---

## How the AI Drafting Works

Studere does not send your data to any external service. Protocol generation runs entirely on-device using Apple's MLX framework with quantized open-source models.

The process:

1. **Serialization** — Your study graph is transformed into a structured text bundle, organized by SPIRIT protocol sections. Each section receives only the nodes relevant to it.

2. **Section-by-section generation** — Each protocol section is generated as an independent LLM call with a focused system prompt and only its relevant data. This avoids the content loss and hallucination risks of asking a small model to produce an entire document at once.

3. **Data fidelity** — The system prompt instructs the model to use only the provided data, preserve the researcher's exact terminology, and output bracketed placeholders for any missing information rather than inventing content.

4. **Streaming with safeguards** — Output streams to the editor in real time. A repetition detector halts generation if the model enters a loop.

5. **Human review** — The draft is editable. You review, revise, endorse, and export. The AI is a transcription tool, not a co-author.

---

## Roadmap

- [ ] Free-form canvas with drag-and-drop node positioning
- [ ] Additional study design templates (case-control, cohort, qualitative designs, mixed methods)
- [ ] SPIRIT checklist cross-referencing and compliance scoring
- [ ] PDF export with formatted protocol document
- [ ] Collaboration via shared project files
- [ ] iPad support

---

## License

Copyright (c) 2026 Zhi Zheng Yeo

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

---

## Acknowledgments

- [MLX](https://github.com/ml-explore/mlx) and [mlx-swift-examples](https://github.com/ml-explore/mlx-swift-examples) by Apple for on-device inference
- [SPIRIT 2013](https://www.spirit-statement.org/) for the protocol reporting guidelines that inform the section structure
- The open-source model community at [HuggingFace](https://huggingface.co/mlx-community) for quantized MLX models
