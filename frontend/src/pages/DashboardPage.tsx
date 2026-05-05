import { useEffect, useState } from "react";
import { ArrowRight, CircleAlert, FileCheck2, Files, Plus, Route } from "lucide-react";
import { Link } from "react-router-dom";
import { ApiError, api } from "../api";
import type { DashboardSummary } from "../types";

export function DashboardPage() {
  const [summary, setSummary] = useState<DashboardSummary | null>(null);
  const [error, setError] = useState("");

  useEffect(() => {
    api.dashboard().then(setSummary).catch((reason) => {
      setError(reason instanceof ApiError ? reason.message : "Could not load dashboard.");
    });
  }, []);

  return (
    <div className="overview">
      <header className="dashboard-header">
        <div>
          <span className="eyebrow">Workspace overview</span>
          <h1>Document operations</h1>
          <p>Track drafts moving through your Writer and Critic workflow.</p>
        </div>
        <Link className="button primary" to="/app/new"><Plus size={18} /> New document</Link>
      </header>
      {error && <div className="notice error">{error}</div>}
      <section className="stat-grid">
        <Metric icon={Files} label="Total drafts" value={summary?.total_documents ?? 0} />
        <Metric icon={FileCheck2} label="Approved structure" value={summary?.approved_documents ?? 0} />
        <Metric icon={CircleAlert} label="Needs review" value={summary?.needs_attention ?? 0} />
        <Metric icon={Route} label="Average cycles" value={summary?.average_iterations ?? 0} />
      </section>
      <section className="recent glass">
        <div className="section-header">
          <h2>Recent documents</h2>
          <Link to="/app/new">Create new <ArrowRight size={16} /></Link>
        </div>
        {!summary?.recent_documents.length ? (
          <div className="empty-state">
            <Files />
            <h3>No documents yet</h3>
            <p>Generate your first reviewed deliverable from notes or meeting transcripts.</p>
          </div>
        ) : (
          <div className="document-list">
            {summary.recent_documents.map((document) => (
              <Link className="document-row" key={document.id} to={`/app/documents/${document.id}`}>
                <div className="document-type">{document.template}</div>
                <div className="document-name">
                  <strong>{document.title}</strong>
                  <small>Updated {new Date(document.updated_at).toLocaleString()}</small>
                </div>
                <span className={`status-pill ${document.status === "approved" ? "approved" : "attention"}`}>
                  {document.status === "approved" ? "Approved" : "Review required"}
                </span>
                <b>{document.review.score}</b>
              </Link>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}

function Metric({ icon: Icon, label, value }: { icon: typeof Files; label: string; value: number }) {
  return (
    <article className="metric glass">
      <Icon />
      <strong>{value}</strong>
      <span>{label}</span>
    </article>
  );
}

