import { useRef } from "react";
import { Bold, Download, Eye, Heading2, Italic, List, Pencil, Quote, Table2 } from "lucide-react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

interface Props {
  content: string;
  onChange: (value: string) => void;
  onDownload?: () => void;
  mode: "edit" | "preview";
  onModeChange: (mode: "edit" | "preview") => void;
}

export function MarkdownEditor({ content, onChange, onDownload, mode, onModeChange }: Props) {
  const textarea = useRef<HTMLTextAreaElement>(null);

  function apply(before: string, after = before, placeholder = "text") {
    const field = textarea.current;
    if (!field) return;
    const start = field.selectionStart;
    const end = field.selectionEnd;
    const selected = content.slice(start, end) || placeholder;
    const next = `${content.slice(0, start)}${before}${selected}${after}${content.slice(end)}`;
    onChange(next);
    requestAnimationFrame(() => {
      field.focus();
      field.setSelectionRange(start + before.length, start + before.length + selected.length);
    });
  }

  function insertBlock(prefix: string, placeholder: string) {
    apply(prefix, "", placeholder);
  }

  return (
    <section className="editor glass">
      <header className="editor-toolbar">
        <div className="format-actions">
          <button onClick={() => apply("**", "**", "bold")} title="Bold" type="button"><Bold size={16} /></button>
          <button onClick={() => apply("*", "*", "italic")} title="Italic" type="button"><Italic size={16} /></button>
          <button onClick={() => insertBlock("\n## ", "Heading")} title="Heading" type="button"><Heading2 size={16} /></button>
          <button onClick={() => insertBlock("\n- ", "List item")} title="List" type="button"><List size={16} /></button>
          <button onClick={() => insertBlock("\n> ", "Important note")} title="Quote" type="button"><Quote size={16} /></button>
          <button
            onClick={() => insertBlock("\n| Column | Detail |\n| --- | --- |\n| Item | Value |\n", "")}
            title="Table"
            type="button"
          >
            <Table2 size={16} />
          </button>
        </div>
        <div className="mode-actions">
          <button className={mode === "edit" ? "active" : ""} onClick={() => onModeChange("edit")} type="button">
            <Pencil size={15} /> Edit
          </button>
          <button className={mode === "preview" ? "active" : ""} onClick={() => onModeChange("preview")} type="button">
            <Eye size={15} /> Preview
          </button>
          {onDownload && (
            <button onClick={onDownload} type="button"><Download size={15} /> Download</button>
          )}
        </div>
      </header>
      {mode === "edit" ? (
        <textarea
          className="markdown-area"
          ref={textarea}
          spellCheck
          value={content}
          onChange={(event) => onChange(event.target.value)}
        />
      ) : (
        <article className="document-preview">
          <ReactMarkdown remarkPlugins={[remarkGfm]}>{content}</ReactMarkdown>
        </article>
      )}
    </section>
  );
}

