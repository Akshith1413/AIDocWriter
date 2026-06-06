export type TemplateId = "prd" | "compliance" | "contract" | "consulting" | "other";
export type ProviderId = "demo" | "openai" | "anthropic" | "groq" | "groq-8b" | "groq-gemma";

export interface ReviewFinding {
  severity: "critical" | "high" | "medium" | "low";
  section: string;
  issue: string;
  recommendation: string;
}

export interface Review {
  status: "approved" | "revision_required";
  score: number;
  summary: string;
  missing_sections: string[];
  findings: ReviewFinding[];
  strengths: string[];
}

export interface GeneratePayload {
  title?: string;
  input_text: string;
  template: TemplateId;
  provider: ProviderId;
  model?: string;
  max_iterations?: number;
  custom_template_label?: string;
  custom_sections?: string[];
}

export interface GenerationResult {
  title: string;
  content_md: string;
  review: Review;
  provider: string;
  model: string;
  iteration_count: number;
  status: string;
  stages: string[];
  remaining_guest_generations?: number;
}

export interface DocumentRecord {
  id: string;
  title: string;
  template: TemplateId;
  source_notes: string;
  content_md: string;
  review: Review;
  provider: string;
  model: string;
  status: string;
  iteration_count: number;
  created_at: string;
  updated_at: string;
  custom_template_label?: string;
  custom_sections?: string[];
}

export interface User {
  id: string;
  name: string;
  email: string;
  created_at: string;
}

export interface AuthResponse {
  access_token: string;
  token_type: string;
  user: User;
}

export interface ProviderOption {
  id: ProviderId;
  name: string;
  configured: boolean;
  default_model: string;
  description: string;
}

export interface TemplateOption {
  id: TemplateId;
  name: string;
  sections: string[];
}

export interface DashboardSummary {
  total_documents: number;
  approved_documents: number;
  needs_attention: number;
  average_iterations: number;
  recent_documents: DocumentRecord[];
}

