import { motion } from "framer-motion";
import {
  ArrowRight,
  CheckCircle2,
  FileDown,
  GitBranch,
  Layers3,
  LockKeyhole,
  PenTool,
  ScanSearch,
  Sparkles,
} from "lucide-react";
import { Link } from "react-router-dom";
import { MarketingHeader } from "../components/AppShell";
import { Backdrop } from "../components/Backdrop";

const features = [
  {
    icon: PenTool,
    title: "Writer Agent",
    copy: "Turns fragments, transcripts, and clauses into rigorous professional drafts with mandatory structure.",
  },
  {
    icon: ScanSearch,
    title: "Critic Agent",
    copy: "Scores every draft against its standard and returns typed issues, recommendations, and omissions.",
  },
  {
    icon: GitBranch,
    title: "Agentic routing",
    copy: "Automatically sends deficient drafts back through revision before they reach human approval.",
  },
  {
    icon: FileDown,
    title: "Production exports",
    copy: "Edit live, preview Markdown, and export work as DOCX, HTML, JSON, or Markdown.",
  },
  {
    icon: Layers3,
    title: "Four standards",
    copy: "PRDs, compliance memos, contract briefs, and consulting decisions arrive pre-rubriced.",
  },
  {
    icon: LockKeyhole,
    title: "Model-flexible",
    copy: "Run locally in demo mode or securely configure OpenAI, Claude, and Groq server-side.",
  },
];

export function LandingPage() {
  return (
    <div className="landing">
      <Backdrop />
      <MarketingHeader />
      <main>
        <section className="hero">
          <motion.div
            className="hero-copy"
            initial={{ opacity: 0, y: 22 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7 }}
          >
            <span className="eyebrow luminous"><Sparkles size={14} /> Professional intelligence, routed</span>
            <h1>
              Documents that draft,
              <span> challenge, and refine themselves.</span>
            </h1>
            <p>
              Aureview transforms raw working notes into polished PRDs, compliance memos,
              contract briefs, and strategic recommendations through a Writer and Critic agent loop.
            </p>
            <div className="hero-actions">
              <Link className="button primary" to="/studio">
                Try 3 generations free <ArrowRight size={18} />
              </Link>
              <Link className="button secondary" to="/signup">
                Create workspace
              </Link>
            </div>
            <div className="trust-row">
              <span><CheckCircle2 size={15} /> Structured output</span>
              <span><CheckCircle2 size={15} /> Human approval retained</span>
              <span><CheckCircle2 size={15} /> Deployable stack</span>
            </div>
          </motion.div>
          <motion.div
            className="hero-console glass"
            initial={{ opacity: 0, x: 35, rotateY: -6 }}
            animate={{ opacity: 1, x: 0, rotateY: 0 }}
            transition={{ duration: 0.9, delay: 0.18 }}
          >
            <div className="console-top">
              <span className="console-dots"><i /><i /><i /></span>
              PRD / onboarding-modernization.md
              <span className="live-dot">LIVE</span>
            </div>
            <div className="agent-track">
              <div className="agent complete"><PenTool size={16} /><b>Writer</b><small>Draft generated</small></div>
              <div className="track-line"><span /></div>
              <div className="agent complete"><ScanSearch size={16} /><b>Critic</b><small>Score 94</small></div>
              <div className="track-line"><span /></div>
              <div className="agent pending"><CheckCircle2 size={16} /><b>Human</b><small>Approve</small></div>
            </div>
            <article className="paper">
              <h3>Client Onboarding Modernization</h3>
              <p className="paper-meta">PRODUCT REQUIREMENTS DOCUMENT / REVIEWED</p>
              <div className="paper-heading">Goals and Success Metrics</div>
              <div className="metric-row"><b>&lt; 30 min</b><span>Target onboarding time</span><em>Validated</em></div>
              <div className="metric-row"><b>100%</b><span>Audit-log coverage</span><em>Validated</em></div>
              <div className="paper-heading">Critic assessment</div>
              <p className="approval"><CheckCircle2 size={15} /> Required sections present. Ready for accountable review.</p>
            </article>
          </motion.div>
        </section>
        <section className="stat-band">
          <div><strong>4</strong><span>document standards</span></div>
          <div><strong>2</strong><span>autonomous agents</span></div>
          <div><strong>100%</strong><span>required heading validation</span></div>
          <div><strong>4</strong><span>download formats</span></div>
        </section>
        <section className="capabilities" id="capabilities">
          <span className="eyebrow">Capabilities</span>
          <h2>A review room built into every draft.</h2>
          <div className="feature-grid">
            {features.map((feature, index) => (
              <motion.article
                className="feature glass"
                initial={{ opacity: 0, y: 18 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: "-50px" }}
                transition={{ delay: index * 0.06 }}
                key={feature.title}
              >
                <feature.icon />
                <h3>{feature.title}</h3>
                <p>{feature.copy}</p>
              </motion.article>
            ))}
          </div>
        </section>
        <section className="workflow" id="workflow">
          <div>
            <span className="eyebrow">LangGraph workflow</span>
            <h2>Quality is a route, not a hope.</h2>
            <p>
              Every generation carries state through drafting, rubric-based critique, conditional
              revision, and accountable human sign-off. Provider secrets never enter the browser.
            </p>
            <Link className="button primary" to="/studio">Open the guest studio <ArrowRight size={18} /></Link>
          </div>
          <div className="flow-diagram glass">
            <div className="flow-node input">Source notes</div>
            <span>→</span>
            <div className="flow-node writer">Writer</div>
            <span>→</span>
            <div className="flow-node critic">Critic JSON</div>
            <span>→</span>
            <div className="flow-node approval">Human review</div>
            <div className="loop-arrow">Missing sections / high risk &nbsp; ↺ &nbsp; revise</div>
          </div>
        </section>
      </main>
      <footer className="site-footer">
        <div><strong>Aureview AI</strong> Agentic document workflow for professional services.</div>
        <Link to="/studio">Start without an account</Link>
      </footer>
    </div>
  );
}

