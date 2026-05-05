import { useEffect, useState } from "react";
import { Download, RefreshCcw, Save } from "lucide-react";
import { useNavigate, useParams } from "react-router-dom";
import { ApiError, api, downloadExport } from "../api";
import { GenerationComposer } from "../components/GenerationComposer";
import { MarkdownEditor } from "../components/MarkdownEditor";
import { ReviewPanel } from "../components/ReviewPanel";
import type { DocumentRecord, GeneratePayload } from "../types";

export function DocumentPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [document, setDocument] = useState<DocumentRecord | null>(null);
  const [content, setContent] = useState("");
  const [mode, setMode] = useState<"edit" | "preview">("preview");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [dirty, setDirty] = useState(false);

  useEffect(() => {
    if (!id) {
      setDocument(null);
      return;
    }
    api.document(id)
      .then((loaded) => {
        setDocument(loaded);
        setContent(loaded.content_md);
        setDirty(false);
      })
      .catch((reason) => setError(reason instanceof ApiError ? reason.message : "Could not load document."));
  }, [id]);

  async function generate(payload: GeneratePayload) {
    setBusy(true);
    setError("");
    try {
      const created = await api.generateDocument(payload);
      navigate(`/app/documents/${created.id}`);
    } catch (reason) {
      setError(reason instanceof ApiError ? reason.message : "Generation failed.");
    } finally {
      setBusy(false);
    }
  }

  async function save() {
    if (!document) return;
    setBusy(true);
    try {
      const saved = await api.saveDocument(document.id, { content_md: content });
      setDocument(saved);
      setDirty(false);
    } catch (reason) {
      setError(reason instanceof ApiError ? reason.message : "Could not save.");
    } finally {
      setBusy(false);
    }
  }

  async function review() {
    if (!document) return;
    setBusy(true);
    setError("");
    try {
      if (dirty) await api.saveDocument(document.id, { content_md: content });
      const reviewed = await api.reviewDocument(document.id, true);
      setDocument(reviewed);
      setContent(reviewed.content_md);
      setDirty(false);
      setMode("preview");
    } catch (reason) {
      setError(reason instanceof ApiError ? reason.message : "Review failed.");
    } finally {
      setBusy(false);
    }
  }

  if (!id) {
    return (
      <div className="new-document">
        <header className="dashboard-header">
          <div><span className="eyebrow">New workflow</span><h1>Create a reviewed document</h1></div>
        </header>
        {error && <div className="notice error">{error}</div>}
        <GenerationComposer busy={busy} onGenerate={generate} />
      </div>
    );
  }

  if (!document) return <div className="loading-panel">{error || "Loading document..."}</div>;

  return (
    <div className="document-workspace">
      <header className="workspace-header">
        <div>
          <span className="eyebrow">{document.template} / {document.provider}</span>
          <h1>{document.title}</h1>
        </div>
        <div className="workspace-actions">
          <button className="button secondary compact" disabled={!dirty || busy} onClick={save}>
            <Save size={16} /> Save
          </button>
          <button className="button primary compact" disabled={busy} onClick={review}>
            <RefreshCcw size={16} /> {busy ? "Running..." : "Critique + refine"}
          </button>
        </div>
      </header>
      {error && <div className="notice error">{error}</div>}
      <div className="exports glass">
        <span><Download size={15} /> Export</span>
        {(["docx", "md", "html", "json"] as const).map((kind) => (
          <button key={kind} onClick={() => downloadExport(document.id, kind)} type="button">
            .{kind}
          </button>
        ))}
      </div>
      <div className="workspace-grid">
        <MarkdownEditor
          content={content}
          mode={mode}
          onChange={(value) => {
            setContent(value);
            setDirty(true);
          }}
          onModeChange={setMode}
        />
        <ReviewPanel iterations={document.iteration_count} review={document.review} />
      </div>
    </div>
  );
}

