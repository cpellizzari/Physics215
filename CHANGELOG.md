# Changelog

A running log of notable changes to the Core Preflights system. Each entry records
**what** changed, **who** made it, and **why**, so future maintainers (and Claude)
can understand the history without re-deriving it from code or git.

Newest entries first. Dates are `YYYY-MM-DD`.

---

## 2026-06-11 — Matthew Recker

### Added — Lesson Interactions feature

A new path alongside the existing assignments system: students work through a Claude
**artifact** (an interactive lesson hosted on claude.ai), and the artifact sends a
compressed Markdown report back to the site to be saved per student. Directors create
and manage these lessons; an AI skill will later summarize trends by section.

**Database — migration [`012_preflight_interaction_reports.sql`](supabase/migrations/012_preflight_interaction_reports.sql)** (purely additive; touches no existing table):
- `interactions` — one row per lesson. `id` is a stable slug (e.g. `lesson-02-charge`)
  the artifact embeds in its submit link. Holds `course_id`, `title`, `description`,
  `artifact_url`, `is_published`.
- `preflight_interaction_reports` — one row per student per interaction
  (`UNIQUE(student_id, interaction_id)`). Stores the report as an inert Markdown blob
  (`report_markdown`, capped at 100 KB), plus an optional `report_data` JSONB for future
  structured fields. Course/section are **not** stored — derived by joining to the student.
- View `interaction_reports_by_section` — joins reports to the student's section for the
  analysis skill.
- RLS: students may only write rows bound to their own `auth_user_id`; directors/admins
  read all; instructors read their own sections.

**New pages:**
- [`interactions-admin.html`](interactions-admin.html) — director/admin page to add/edit
  (modal), publish, delete lessons, and view submissions. Submissions are picked by
  section → student dropdown (scales to ~1000 students; fetches one report at a time) and
  rendered as sanitized Markdown.
- [`interactions.html`](interactions.html) — student-facing list of published lessons with
  **Launch** links to the artifacts.
- [`interaction-submit.html`](interaction-submit.html) — receives the artifact's
  `#i=<slug>&r=<lz-string payload>` URL, requires student login, and upserts the report.

**Why these choices:**
- *Separate tables, not reusing `assignments`* — interactions may eventually replace
  assignments, but the existing tables are working in production and were left untouched.
- *Report stored as a blob, sanitized only on render (DOMPurify)* — DB data is never
  executed; XSS is a render-time concern. The `#r=` payload is user-controllable, so it's
  treated as untrusted everywhere it's displayed.
- *Data passed via URL hash, not POST* — GitHub Pages is static and can't process a POST;
  the hash also keeps payloads out of server logs/referrers.
- *RLS is the real gate* — `students.auth_user_id = auth.uid()` makes a spoofed
  `student_id` impossible to write, regardless of client code.

**Deferred (not yet built):** a home for the analysis skill's *output* (per-section trend
summaries). Options: a sibling `interaction_section_summaries` table, or mirror the
existing `assignments.analysis_report` JSONB pattern.
