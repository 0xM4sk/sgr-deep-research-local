# 🧠 SGR Deep Research - Schema-Guided Reasoning System

https://github.com/user-attachments/assets/a5e34116-7853-43c2-ba93-2db811b8584a

Fully Local (<8B) Automated research system using Schema-Guided Reasoning (SGR).

Credits
- Originator: vakovalskii/sgr-deep-research

Current State (Local Stack)
- Fully local SGR via LiteLLM + Ollama is working with sub‑8B models (e.g., llama3‑8b, gemma‑7b/9b). The streaming app guides models to produce structured JSON reliably, then renders and saves Markdown reports.
- Airsroute gateway integration is work‑in‑progress (WIP) and optional.

Local Run (LiteLLM + Ollama)
- Install deps: `pip install -r sgr-streaming/requirements.txt`
- Start Ollama: `ollama serve` (ensure your target model is pulled, e.g., `ollama pull llama3:8b`)
- Start LiteLLM proxy: `litellm --config sgr-streaming/proxy/litellm_config.yaml --host 0.0.0.0 --port 8000`
- Configure `sgr-streaming/config.yaml`:
  - `openai.api_key: dev-key`
  - `openai.base_url: http://localhost:8000/v1`
  - `openai.model: sgr-gemma` (or the model alias from `litellm_config.yaml`)
- Run streaming app: `python sgr-streaming/sgr_streaming.py`

Notes
- Strictness knobs for report saving are configurable in `execution` (e.g., `strict_report_quality`, `min_report_words`).
- Airsroute gateway and dashboard exist but are optional; they will be documented when stable.

## 📁 Project Structure

```
sgr-deep-research/
├── sgr-classic/          # 🔍 Classic SGR version
│   ├── sgr-deep-research.py
│   ├── scraping.py
│   ├── config.yaml
│   ├── requirements.txt
│   └── README.md
│
├── sgr-streaming/        # 🚀 Enhanced streaming version
│   ├── sgr_streaming.py
│   ├── enhanced_streaming.py
│   ├── sgr_visualizer.py
│   ├── sgr_step_tracker.py
│   ├── demo_enhanced_streaming.py
│   ├── compact_streaming_example.py
│   ├── scraping.py
│   ├── config.yaml
│   ├── requirements.txt
│   └── README.md
│
└── reports/              # 📊 Generated reports
```

## 🚀 Quick Start

### Classic Version (Simple and stable)
```bash
cd sgr-classic
python sgr-deep-research.py
```

### Streaming Version (Modern with animations)
```bash
cd sgr-streaming
python sgr_streaming.py
```

Tip
- If running locally via LiteLLM + Ollama, ensure `config.yaml` points to the proxy and model alias as shown above.

## 🔍 Version Comparison

| Feature | SGR Classic | SGR Streaming |
|---------|-------------|---------------|
| **Interface** | Simple text | Interactive with animations |
| **JSON Parsing** | Static | Real-time streaming |
| **Visualization** | Basic | Schema trees + metrics |
| **Metrics** | Simple | Detailed + performance |
| **SGR Steps** | Text log | Visual pipeline |
| **Animations** | None | Spinners, progress bars |
| **Stability** | ✅ High | ✅ Stable |
| **Simplicity** | ✅ Maximum | Medium |
| **Functionality** | Basic | ✅ Extended |

## 🎯 Version Selection Guide

### Choose **SGR Classic** if:
- 🔧 Need simple and stable system
- 💻 Limited terminal resources
- 📝 Focus on results, not process
- 🚀 Quick deployment

### Choose **SGR Streaming** if:
- 🎨 Process visualization is important
- 📊 Need detailed metrics
- 🔍 Want to see real-time JSON parsing
- 🎬 Prefer modern interfaces

## ⚙️ General Setup

1. **Create config.yaml from example:**
```bash
cp config.yaml.example config.yaml
```

2. **Configure API keys:**
```yaml
openai:
  api_key: "your-openai-api-key"
  
tavily:
  api_key: "your-tavily-api-key"
```

3. **Install dependencies:**
```bash
# For classic version
cd sgr-classic && pip install -r requirements.txt

# For streaming version  
cd sgr-streaming && pip install -r requirements.txt
```

## 🎬 Demo (Streaming)

```bash
cd sgr-streaming

# Full feature demonstration
python demo_enhanced_streaming.py

# Compact streaming example
python compact_streaming_example.py
```

## 📊 SGR Capabilities

### Schema-Guided Reasoning includes:
1. **🤔 Clarification** - clarifying questions when unclear
2. **📋 Plan Generation** - research plan creation  
3. **🔍 Web Search** - internet information search
4. **🔄 Plan Adaptation** - plan adaptation based on results
5. **📝 Report Creation** - detailed report creation
6. **✅ Completion** - task completion

### Example tasks:
- "Find information about BMW X6 2025 prices in Russia"
- "Research current AI trends"
- "Analyze cryptocurrency market in 2024"

## 🧠 Why SGR + Structured Output?

### The Problem with Function Calling on Local Models
**Reality Check:** Function Calling works great on OpenAI/Anthropic (80+ BFCL scores) but fails on local models <32B parameters.

**Test Results:**
- `Qwen3-4B`: Only 2% accuracy in Agentic mode (BFCL benchmark)
- Local models know **HOW** to call tools, but not **WHEN** to call them
- Result: `{"tool_calls": null, "content": "Text instead of tool call"}`

### SGR Solution: Forced Reasoning → Deterministic Execution

```python
# Phase 1: Structured Output reasoning (100% reliable)
reasoning = model.generate(format="json_schema")

# Phase 2: Deterministic execution (no model uncertainty)  
result = execute_plan(reasoning.actions)
```

### Architecture by Model Size

| Model Size | Recommended Approach | Why |
|------------|---------------------|-----|
| **<14B** | Pure SGR + Structured Output | FC accuracy too low, SO forces reasoning |
| **14-32B** | SGR as tool + FC hybrid | Best of both worlds |
| **32B+** | Native FC + SGR fallback | FC works reliably |

### SGR vs Function Calling

| Aspect | Traditional FC | SGR + Structured Output |
|--------|---------------|------------------------|
| **When to think** | Model decides ❌ | Always forced ✅ |
| **Reasoning quality** | Unpredictable ❌ | Structured & consistent ✅ |
| **Local model support** | <35% accuracy ❌ | 100% on simple tasks ✅ |
| **Deterministic** | No ❌ | Yes ✅ |

**Bottom Line:** Don't force <32B models to pretend they're GPT-4o. Let them think structurally through SGR, then execute deterministically.

## 🔧 Configuration

### Main parameters:
```yaml
openai:
  model: "gpt-4o-mini"     # Model for reasoning
  max_tokens: 8000         # Maximum tokens
  temperature: 0.4         # Creativity (0-1)

execution:
  max_steps: 6            # Maximum SGR steps
  reports_dir: "reports"  # Reports directory
  # Optional report quality knobs (Streaming)
  strict_report_quality: false
  min_report_words: 300
  min_report_words_forced: 150

search:
  max_results: 10         # Search results count

scraping:
  enabled: false         # Web scraping
  max_pages: 5          # Maximum pages
```

## 📝 Reports

All reports are saved to `reports/` directory in format:
```
YYYYMMDD_HHMMSS_Task_Name.md
```

Reports contain:
- 📋 Executive summary
- 🔍 Technical analysis with citations
- 📊 Key findings  
- 📎 Sources list

## 🐛 Fixed Issues (Streaming)

✅ **Large gaps after streaming** - compact panels  
✅ **Planning step duplication** - proper tracking  
✅ **Clarification questions not displayed** - special handling  
✅ **Schema overlapping Completed block** - proper spacing  

## 🤝 Usage

Both versions are compatible and use the same configuration format. For local setups on small models (<8B), the streaming version with LiteLLM + Ollama is recommended.

Removed Modules
- The experimental `sgr_streaming_ec/` (error‑corrected streaming) module has been removed to simplify the codebase and focus on the main streaming path.

---

🧠 **Choose the right SGR version for your research tasks!**
