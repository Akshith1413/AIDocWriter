import { Sparkles } from "lucide-react";
import { Link } from "react-router-dom";

export function Brand() {
  return (
    <Link className="brand" to="/">
      <span className="brand-mark">
        <Sparkles size={18} />
      </span>
      <span>
        <strong>Aureview</strong>
        <small>Agentic Documents</small>
      </span>
    </Link>
  );
}

