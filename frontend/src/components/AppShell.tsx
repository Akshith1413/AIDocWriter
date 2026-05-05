import { LayoutDashboard, LogOut, PenLine } from "lucide-react";
import { Link, NavLink, Outlet } from "react-router-dom";
import { useAuth } from "../auth";
import { Backdrop } from "./Backdrop";
import { Brand } from "./Brand";

export function MarketingHeader() {
  const { user } = useAuth();
  return (
    <header className="marketing-header">
      <Brand />
      <nav className="nav-links">
        <a href="/#capabilities">Capabilities</a>
        <a href="/#workflow">Workflow</a>
        <Link to="/studio">Guest studio</Link>
      </nav>
      <div className="nav-actions">
        {user ? (
          <Link className="button primary compact" to="/app">
            Dashboard
          </Link>
        ) : (
          <>
            <Link className="button ghost compact" to="/signin">
              Sign in
            </Link>
            <Link className="button primary compact" to="/signup">
              Get started
            </Link>
          </>
        )}
      </div>
    </header>
  );
}

export function DashboardShell() {
  const { user, signout } = useAuth();
  return (
    <div className="application">
      <Backdrop />
      <aside className="sidebar glass">
        <Brand />
        <nav className="sidebar-nav">
          <NavLink end to="/app">
            <LayoutDashboard size={18} /> Overview
          </NavLink>
          <NavLink to="/app/new">
            <PenLine size={18} /> New document
          </NavLink>
        </nav>
        <div className="account-card">
          <div className="avatar">{user?.name.slice(0, 1).toUpperCase()}</div>
          <div>
            <strong>{user?.name}</strong>
            <small>{user?.email}</small>
          </div>
          <button aria-label="Sign out" onClick={signout}>
            <LogOut size={16} />
          </button>
        </div>
      </aside>
      <main className="dashboard-main">
        <Outlet />
      </main>
    </div>
  );
}

