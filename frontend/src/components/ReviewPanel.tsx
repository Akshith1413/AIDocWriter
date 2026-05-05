import { AlertCircle, CheckCircle2, Route, ShieldCheck } from "lucide-react";
import type { CSSProperties } from "react";
import type { Review } from "../types";

interface Props {
  review: Review;
  iterations: number;
  stages?: string[];
}

export function ReviewPanel({ review, iterations, stages = [] }: Props) {
  const approved = review.status === "approved";
  return (
    <aside className="review-panel glass">
      <div
        className={`score-ring ${approved ? "approved" : "attention"}`}
        style={{ "--score": review.score } as CSSProperties}
      >
        <strong>{review.score}</strong>
        <span>critic score</span>
      </div>
      <div className={`status-pill ${approved ? "approved" : "attention"}`}>
        {approved ? <ShieldCheck size={15} /> : <AlertCircle size={15} />}
        {approved ? "Structurally approved" : "Review required"}
      </div>
      <p className="review-summary">{review.summary}</p>
      <div className="review-meta">
        <Route size={16} /> {iterations} writer cycle{iterations === 1 ? "" : "s"}
      </div>
      {review.findings.length > 0 && (
        <div className="finding-list">
          <h3>Findings</h3>
          {review.findings.map((finding, index) => (
            <div className={`finding ${finding.severity}`} key={`${finding.section}-${index}`}>
              <span>{finding.severity}</span>
              <strong>{finding.section}</strong>
              <p>{finding.issue}</p>
              <small>{finding.recommendation}</small>
            </div>
          ))}
        </div>
      )}
      <div className="strengths">
        <h3>Validated signals</h3>
        {review.strengths.map((strength) => (
          <p key={strength}><CheckCircle2 size={14} /> {strength}</p>
        ))}
      </div>
      {stages.length > 0 && (
        <div className="timeline">
          <h3>Agent trace</h3>
          {stages.map((stage, index) => (
            <p key={stage}><span>{index + 1}</span>{stage}</p>
          ))}
        </div>
      )}
    </aside>
  );
}
