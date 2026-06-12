# Changelog

A running log of notable changes to the Core Preflights system. Each entry records
**what** changed, **who** made it, and **why**, so future maintainers (and Claude)
can understand the history without re-deriving it from code or git.

Newest entries first. Dates are `YYYY-MM-DD`.

---

## 2026-06-11 — Matthew Recker

### Added — Grade & Report ported into the `app/` portal

Second refactor pass: the two daily-use faculty tools now live natively in the portal
shell (top nav, theme, course switcher), no longer requiring the legacy `admin.html`.

- [`app/faculty/grade.html`](app/faculty/grade.html) + [`app/js/faculty-grade.js`](app/js/faculty-grade.js)
  — the full grading workflow: assignment + section pickers, the 3-state credit toggle
  (full → warn → zero), per-question feedback, "only flagged" filter, per-student totals,
  save-draft / finalize-&-publish, reopen, and grant/edit/remove extensions. Same
  `scores.question_scores` shape, `is_finalized` semantics, and `extensions` writes as the
  legacy tab — a faithful port, restyled with theme tokens and delegated events.
- [`app/faculty/report.html`](app/faculty/report.html) + [`app/js/faculty-report.js`](app/js/faculty-report.js)
  — submission summary, "did not submit" list, and per-question cards showing the
  `analysis_report` class summaries (from `/preflight-analyze`) plus raw responses with
  show-names, random-10 sampling, and copy-to-clipboard.
- Faculty **nav** now exposes Grade and Report directly; a single **Admin ↗** link covers
  the still-legacy director tools. Dashboard quick-actions point Grade/Report at the new
  internal pages.

Still legacy (next passes): Assignments builder, Roster, Sections, Instructors, Export.

### Added — `app/` role-based portal (foundation pass)

A coherent, role-aware rewrite of the front end living in a new [`app/`](app/) subfolder,
built to be promoted to the repo root later. **No database or RLS changes.** This first
("foundation") pass ships the shell, theming, navigation, both dashboards, and the
interaction views; the heavy grading / roster / sections / assignment-builder / export
tools stay on the legacy pages and are reached via out-links until ported in a later pass.

**Why:** the legacy pages each re-implemented their own login card, session check, and
`esc()` helper, had no shared module, no dashboard landing, and a single light-only theme.
The portal unifies all of that behind one auth bootstrap and a top nav with light/dark mode.

**Shared shell ([`app/js/`](app/js/)):**
- `config.js` — copy of the root client (sets `window.db`); kept identical so paths don't
  change after promotion. `supabase.js` re-exports it as an ES module.
- `auth.js` — one `bootstrap({ require })` every page calls: restores the persisted session
  (survives reload + navigation), redirects unauthenticated users to login with a `?next`
  round-trip, resolves role by **table membership** (instructors vs students), resolves the
  faculty course list + persisted current course (ports `admin.html`'s `initAdmin`
  fallbacks) or the student's course (derived from their section), and enforces the page's
  required role.
- `nav.js` — shared top navigation: role links, faculty **course switcher**, theme toggle,
  user menu, mobile menu. `theme.js` — `data-theme` dark mode (localStorage +
  `prefers-color-scheme`, no-flash head snippet). `util.js` — `esc()`, due-date/section
  logic, an emoji-fallback `iconHTML()`, and `legacyUrl()` (resolves root-level legacy
  links correctly both at `/app/` and after promotion).
- `student-data.js` / `faculty-data.js` — batched, no-N+1 dashboard queries over existing
  tables only.

**Pages:** [`app/login.html`](app/login.html) (unified cadet-ID-or-email login),
[`app/index.html`](app/index.html) (role router), student
[dashboard](app/student/dashboard.html) / [assignments](app/student/assignments.html)
(ported submit+review engine) / [interactions](app/student/interactions.html), and faculty
[dashboard](app/faculty/dashboard.html) (per-section submission/grading roll-up) /
[interactions](app/faculty/interactions.html) (completion roll-up + per-student report viewer).

**Design system:** [`app/css/styles.css`](app/css/styles.css) is the legacy sheet with its
~14 hardcoded surface/alert colors tokenized into CSS variables plus a `[data-theme="dark"]`
set, extended with top-nav, stat-tile, and roll-up components.

**Icons:** [`app/media/icons/ICON-SEARCH-PROMPT.md`](app/media/icons/ICON-SEARCH-PROMPT.md)
is a ready-to-run prompt to source ~35 cohesive **Lineal Color** icons; the UI references
their filenames and falls back to emoji until they're dropped in. See
[`app/README.md`](app/README.md) for the structure and go-live steps.

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
