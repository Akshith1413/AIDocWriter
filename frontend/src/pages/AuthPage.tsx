import { useState, type FormEvent } from "react";
import { ArrowRight, ShieldCheck } from "lucide-react";
import { Link, Navigate, useNavigate } from "react-router-dom";
import { ApiError, api } from "../api";
import { useAuth } from "../auth";
import { MarketingHeader } from "../components/AppShell";
import { Backdrop } from "../components/Backdrop";

export function AuthPage({ mode }: { mode: "signin" | "signup" }) {
  const { user, authenticate } = useAuth();
  const navigate = useNavigate();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const signup = mode === "signup";

  if (user) return <Navigate replace to="/app" />;

  async function submit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError("");
    try {
      const response = signup
        ? await api.signup({ name, email, password })
        : await api.signin({ email, password });
      authenticate(response);
      navigate("/app");
    } catch (reason) {
      setError(reason instanceof ApiError ? reason.message : "Could not authenticate.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="auth-page">
      <Backdrop />
      <MarketingHeader />
      <main className="auth-wrap">
        <section className="auth-message">
          <span className="eyebrow">Aureview workspace</span>
          <h1>{signup ? "Build your document command center." : "Welcome back to review."}</h1>
          <p>Store drafts securely, refine after edits, monitor review status, and export professional deliverables.</p>
          <div className="auth-benefit"><ShieldCheck /> Your model API keys stay exclusively on your server deployment.</div>
        </section>
        <form className="auth-form glass" onSubmit={submit}>
          <h2>{signup ? "Create account" : "Sign in"}</h2>
          <p>{signup ? "Begin with a persistent private workspace." : "Continue your reviewed documents."}</p>
          {signup && (
            <label className="field">
              <span>Full name</span>
              <input required minLength={2} value={name} onChange={(event) => setName(event.target.value)} />
            </label>
          )}
          <label className="field">
            <span>Work email</span>
            <input required type="email" value={email} onChange={(event) => setEmail(event.target.value)} />
          </label>
          <label className="field">
            <span>Password</span>
            <input
              required
              minLength={8}
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
            />
          </label>
          {error && <p className="form-error">{error}</p>}
          <button className="button primary" disabled={busy} type="submit">
            {busy ? "Working..." : signup ? "Create workspace" : "Sign in"} <ArrowRight size={17} />
          </button>
          <p className="switch-auth">
            {signup ? "Already have an account? " : "New to Aureview? "}
            <Link to={signup ? "/signin" : "/signup"}>{signup ? "Sign in" : "Create account"}</Link>
          </p>
        </form>
      </main>
    </div>
  );
}

