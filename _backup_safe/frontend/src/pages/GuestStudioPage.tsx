import { useState } from "react";
import { Link } from "react-router-dom";
import { ApiError, api, downloadGuest } from "../api";
import { MarketingHeader } from "../components/AppShell";
import { Backdrop } from "../components/Backdrop";
import { GenerationComposer } from "../components/GenerationComposer";
import { MarkdownEditor } from "../components/MarkdownEditor";
import { ReviewPanel } from "../components/ReviewPanel";
import type { GeneratePayload, GenerationResult } from "../types";

export function GuestStudioPage() {
  const [result, setResult] = useState<GenerationResult | null>(null);
  const [content, setContent] = useState("");
  const [mode, setMode] = useState<"edit" | "preview">("preview");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  async function generate(payload: GeneratePayload) {
    setBusy(true);
    setError("");
    try {
      const generated = await api.guestGenerate(payload);
      setResult(generated);
      setContent(generated.content_md);
      setMode("preview");
    } catch (reason) {
      setError(reason instanceof ApiError ? reason.message : "Generation failed.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="studio-page">
      <Backdrop />
      <MarketingHeader />
      <header className="studio-intro">
        <span className="eyebrow">No account required</span>
        <h1>Guest document studio</h1>
        <p>Draft and review up to three documents today. Create a workspace to retain and export full project history.</p>
      </header>
      <main className={result ? "studio-grid has-result" : "studio-grid"}>
        <GenerationComposer busy={busy} compact={Boolean(result)} onGenerate={generate} />
        {error && <div className="notice error">{error}</div>}
        {result && (
          <>
            <section className="result-heading">
              <div>
                <span className="eyebrow">Generated deliverable</span>
                <h2>{result.title}</h2>
              </div>
              <div className="remaining">
                {result.remaining_guest_generations} guest generation{result.remaining_guest_generations === 1 ? "" : "s"} remaining
              </div>
            </section>
            <MarkdownEditor
              content={content}
              mode={mode}
              onChange={setContent}
              onDownload={() => downloadGuest(content, result.title)}
              onModeChange={setMode}
            />
            <ReviewPanel iterations={result.iteration_count} review={result.review} stages={result.stages} />
            <div className="studio-upgrade glass">
              <strong>Keep the document alive.</strong>
              <span>Save revisions, export DOCX, and rerun the reviewer in a private workspace.</span>
              <Link className="button primary compact" to="/signup">Create workspace</Link>
            </div>
          </>
        )}
      </main>
    </div>
  );
}

