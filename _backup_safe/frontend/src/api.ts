import type {
  AuthResponse,
  DashboardSummary,
  DocumentRecord,
  GeneratePayload,
  GenerationResult,
  ProviderOption,
  TemplateOption,
  User,
} from "./types";

const API_ROOT = import.meta.env.VITE_API_URL ?? "/api";
const TOKEN_KEY = "aureview_access_token";
const GUEST_KEY = "aureview_guest_session";

export class ApiError extends Error {
  status: number;

  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

export function getToken(): string | null {
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string | null): void {
  if (token) localStorage.setItem(TOKEN_KEY, token);
  else localStorage.removeItem(TOKEN_KEY);
}

function guestSession(): string {
  let value = localStorage.getItem(GUEST_KEY);
  if (!value) {
    value = crypto.randomUUID();
    localStorage.setItem(GUEST_KEY, value);
  }
  return value;
}

async function request<T>(path: string, init: RequestInit = {}, auth = false): Promise<T> {
  const headers = new Headers(init.headers);
  if (!(init.body instanceof FormData)) headers.set("Content-Type", "application/json");
  if (auth) {
    const token = getToken();
    if (!token) throw new ApiError(401, "Please sign in to continue.");
    headers.set("Authorization", `Bearer ${token}`);
  }
  const response = await fetch(`${API_ROOT}${path}`, { ...init, headers });
  if (!response.ok) {
    const payload = (await response.json().catch(() => ({}))) as { detail?: string };
    throw new ApiError(response.status, payload.detail ?? "Request failed.");
  }
  if (response.status === 204) return undefined as T;
  return (await response.json()) as T;
}

export const api = {
  providers: () => request<ProviderOption[]>("/public/providers"),
  templates: () => request<TemplateOption[]>("/public/templates"),
  guestGenerate: (payload: GeneratePayload) =>
    request<GenerationResult>("/public/generate", {
      method: "POST",
      headers: { "X-Guest-Session": guestSession() },
      body: JSON.stringify(payload),
    }),
  signup: (payload: { name: string; email: string; password: string }) =>
    request<AuthResponse>("/auth/signup", { method: "POST", body: JSON.stringify(payload) }),
  signin: (payload: { email: string; password: string }) =>
    request<AuthResponse>("/auth/signin", { method: "POST", body: JSON.stringify(payload) }),
  me: () => request<User>("/auth/me", {}, true),
  dashboard: () => request<DashboardSummary>("/documents/dashboard", {}, true),
  documents: () => request<DocumentRecord[]>("/documents", {}, true),
  document: (id: string) => request<DocumentRecord>(`/documents/${id}`, {}, true),
  generateDocument: (payload: GeneratePayload) =>
    request<DocumentRecord>(
      "/documents/generate",
      { method: "POST", body: JSON.stringify(payload) },
      true,
    ),
  saveDocument: (id: string, payload: { title?: string; content_md?: string }) =>
    request<DocumentRecord>(
      `/documents/${id}`,
      { method: "PATCH", body: JSON.stringify(payload) },
      true,
    ),
  reviewDocument: (id: string, autoRefine = true) =>
    request<DocumentRecord>(`/documents/${id}/review?auto_refine=${autoRefine}`, { method: "POST" }, true),
  deleteDocument: (id: string) => request<void>(`/documents/${id}`, { method: "DELETE" }, true),
};

export async function downloadExport(id: string, kind: "md" | "json" | "html" | "docx"): Promise<void> {
  const response = await fetch(`${API_ROOT}/documents/${id}/export/${kind}`, {
    headers: { Authorization: `Bearer ${getToken()}` },
  });
  if (!response.ok) throw new ApiError(response.status, "Export failed.");
  const blob = await response.blob();
  const url = URL.createObjectURL(blob);
  const disposition = response.headers.get("content-disposition") ?? "";
  const filename = disposition.match(/filename="([^"]+)"/)?.[1] ?? `document.${kind}`;
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  URL.revokeObjectURL(url);
}

export function downloadGuest(content: string, title: string): void {
  const safeName = title.replace(/[^a-z0-9]+/gi, "-").toLowerCase() || "aureview-draft";
  const blob = new Blob([content], { type: "text/markdown;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = `${safeName}.md`;
  anchor.click();
  URL.revokeObjectURL(url);
}

