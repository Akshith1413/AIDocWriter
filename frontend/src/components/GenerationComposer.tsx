import { useEffect, useState, type FormEvent } from "react";
import { ArrowRight, Cpu, FileText, WandSparkles } from "lucide-react";
import { motion } from "framer-motion";
import { api } from "../api";
import type { GeneratePayload, ProviderId, ProviderOption, TemplateId, TemplateOption } from "../types";

const samples: Record<TemplateId, string> = {
  prd: "Create a client onboarding portal. Users upload ID documents, track verification, and receive reminders. Target is reducing onboarding time from 3 days to under 30 minutes. Need audit logs, accessibility, and admin exceptions.",
  compliance: "Quarterly vendor access review for customer data systems. Evidence includes access export and manager attestations. Two expired contractor accounts appeared active. Need remediation owners and approval record.",
  contract: "Review a proposed SaaS vendor agreement for analytics tooling. Annual value $85,000, handles customer usage data, auto-renews yearly, and vendor requests unlimited liability exclusions.",
  consulting: "A regional advisory team has slow proposal turnaround and inconsistent quality checks. Leadership wants a 60-day pilot for assisted drafting with clear ROI and adoption measures.",
  other: "Provide your source notes or meeting transcripts here. The Writer Agent will organize them and draft a document with the custom sections specified above.",
};

const fallbackTemplates: TemplateOption[] = [
  { id: "prd", name: "Product Requirements Document", sections: [] },
  { id: "compliance", name: "Compliance Review Memo", sections: [] },
  { id: "contract", name: "Contract Review Brief", sections: [] },
  { id: "consulting", name: "Consulting Decision Memo", sections: [] },
  { id: "other", name: "Custom Document", sections: [] },
];

interface Props {
  onGenerate: (payload: GeneratePayload) => Promise<void>;
  busy: boolean;
  compact?: boolean;
}

export function GenerationComposer({ onGenerate, busy, compact = false }: Props) {
  const [templates, setTemplates] = useState<TemplateOption[]>([]);
  const [providers, setProviders] = useState<ProviderOption[]>([]);
  const [template, setTemplate] = useState<TemplateId>("prd");
  const [provider, setProvider] = useState<ProviderId>("groq");
  const [model, setModel] = useState("llama-3.3-70b-versatile");
  const [title, setTitle] = useState("");
  const [notes, setNotes] = useState(samples.prd);
  const [customLabel, setCustomLabel] = useState("Custom Document");
  const [customSectionsText, setCustomSectionsText] = useState("Executive Summary, Overview, Details, Risks and Next Steps");

  useEffect(() => {
    Promise.all([api.templates(), api.providers()]).then(([nextTemplates, nextProviders]) => {
      setTemplates(nextTemplates);
      setProviders(nextProviders);
    });
  }, []);

  function selectTemplate(value: TemplateId) {
    setTemplate(value);
    setNotes(samples[value]);
  }

  function selectProvider(value: ProviderId) {
    setProvider(value);
    const chosen = providers.find((entry) => entry.id === value);
    setModel(chosen?.default_model ?? "studio-demo");
  }

  async function submit(event: FormEvent) {
    event.preventDefault();
    const payload: GeneratePayload = {
      title: title || undefined,
      input_text: notes,
      template,
      provider,
      model,
      max_iterations: 3,
    };
    if (template === "other") {
      payload.custom_template_label = customLabel;
      payload.custom_sections = customSectionsText
        .split(",")
        .map((s) => s.trim())
        .filter(Boolean);
    }
    await onGenerate(payload);
  }

  return (
    <form className={`composer glass ${compact ? "compact-composer" : ""}`} onSubmit={submit}>
      <div className="composer-heading">
        <span className="eyebrow"><WandSparkles size={14} /> Writer Agent input</span>
        <h2>Shape your source material</h2>
      </div>
      <div className="template-row">
        {(templates.length ? templates : fallbackTemplates).map((entry) => (
          <button
            className={entry.id === template ? "template active" : "template"}
            key={entry.id}
            onClick={() => selectTemplate(entry.id)}
            type="button"
          >
            <FileText size={15} />
            {entry.id === "other" ? "Other / Custom" : entry.name.replace(" Document", "").replace(" Review", "")}
          </button>
        ))}
      </div>
      {template === "other" && (
        <div className="model-grid">
          <label className="field">
            <span>Custom document type name</span>
            <input
              required
              value={customLabel}
              onChange={(event) => setCustomLabel(event.target.value)}
              placeholder="e.g., Security Audit Report"
            />
          </label>
          <label className="field">
            <span>Required sections (comma-separated)</span>
            <input
              required
              value={customSectionsText}
              onChange={(event) => setCustomSectionsText(event.target.value)}
              placeholder="e.g., Executive Summary, Findings, Remediation"
            />
          </label>
        </div>
      )}
      <label className="field">
        <span>Optional document title</span>
        <input
          value={title}
          onChange={(event) => setTitle(event.target.value)}
          placeholder="Q3 Client Onboarding Modernization"
        />
      </label>
      <label className="field">
        <span>Meeting notes, clauses, or rough requirements</span>
        <textarea
          className="source-input"
          minLength={20}
          required
          value={notes}
          onChange={(event) => setNotes(event.target.value)}
        />
      </label>
      <label className="field">
        <span><Cpu size={14} /> Model provider</span>
        <select value={provider} onChange={(event) => selectProvider(event.target.value as ProviderId)}>
          {providers.map((entry) => (
            <option disabled={!entry.configured} key={entry.id} value={entry.id}>
              {entry.name}{entry.configured ? "" : " (not configured)"}
            </option>
          ))}
          {!providers.length && <option value="demo">Aureview Demo Engine (In Progress)</option>}
        </select>
      </label>
      <motion.button
        className="button primary generate"
        disabled={busy}
        whileHover={{ y: -2 }}
        whileTap={{ scale: 0.98 }}
        type="submit"
      >
        {busy ? <span className="spinner" /> : <WandSparkles size={18} />}
        {busy ? "Agents are reviewing..." : "Generate reviewed document"}
        {!busy && <ArrowRight size={18} />}
      </motion.button>
    </form>
  );
}
