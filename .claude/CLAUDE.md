# Physics Assignments — Project Overview

A GitHub Pages + Supabase system for managing physics preflight assignments at USAFA. Replaces GradeScope for two courses: Physics 110 and Physics 215.

## Tech Stack

- **Frontend**: Static HTML/CSS/JS hosted on GitHub Pages (no build step)
- **Backend**: Supabase (PostgreSQL + Auth + REST API)
- **Auth**: Supabase Auth for both instructors (email/password) and students (cadetID@usafa.edu / last-6-digits default password)
- **Analysis**: `/preflight-analyze` Claude Code skill (see `.claude/skills/preflight-analyze/`)

## Key Files

| File | Purpose |
|---|---|
| `index.html` | Student-facing assignment submission and grade review |
| `admin.html` | Instructor grading panel (Grade, Report, Assignments, Roster, Sections, Export tabs) |
| `interactions-admin.html` | Director/admin: add/edit/publish lesson interactions, view per-student reports |
| `interactions.html` | Student-facing list of published lesson interactions (Launch links) |
| `interaction-submit.html` | Receives a Claude artifact's compressed report and saves it per student |
| `js/config.js` | Supabase URL + anon key (safe to commit) |
| `css/styles.css` | Shared styles |
| `supabase/seed_full.sql` | Test data for local development |
| `CHANGELOG.md` | Running, attributed log of notable changes — update when shipping features or editing these docs |

## Database Tables

| Table | Purpose |
|---|---|
| `courses` | `phys-110`, `phys-215` |
| `students` | Cadet roster; `auth_user_id` links to Supabase Auth |
| `sections` | Class sections like `M1A`, `T3B`; scoped to a `course_id` |
| `instructors` | Instructor accounts; `is_global_admin` for cross-course access |
| `instructor_course_access` | Per-course roles: `instructor` or `director` |
| `assignments` | Assignment definitions with JSONB `questions`; scoped to `course_id` |
| `responses` | Student JSONB answers; unique on `(student_id, assignment_id)` |
| `scores` | Graded scores with `question_scores` JSONB and `is_finalized` flag |
| `interactions` | Lesson interactions (Claude artifacts); `id` is a slug like `lesson-02-charge`; has `artifact_url`, `is_published` |
| `preflight_interaction_reports` | Student reports from interactions; Markdown blob, unique on `(student_id, interaction_id)` |

## Section Naming Convention

`[M|T][1|3|5][A-D]` — M = M-day, T = T-day; number = period; letter = section within period.
M-day sections use `due_date_m` on assignments; T-day sections use `due_date_t`.

## Lesson Interactions (Claude Artifacts)

*Added 2026-06-11 by Matthew Recker — see `CHANGELOG.md`.*

A second path alongside assignments. A **lesson interaction** is a Claude artifact (an
interactive lesson hosted on claude.ai). Students launch it, work through it, and the
artifact sends a compressed Markdown **report** back to the site to be saved per student.
An AI skill will later summarize trends by section.

**Flow:**
1. A director adds an interaction in `interactions-admin.html` — gives it a slug
   (`lesson-02-charge`), title, course, and `artifact_url`, then publishes it.
2. A student opens `interactions.html`, clicks **Launch**, and the artifact opens on claude.ai.
3. On finish, the artifact opens
   `interaction-submit.html#i=<slug>&r=<lz-string payload>` — data rides in the **URL hash**
   (GitHub Pages is static and can't accept a POST; the hash also keeps payloads out of logs).
4. `interaction-submit.html` decompresses the report, requires student login, and upserts
   into `preflight_interaction_reports`.

**The artifact↔site contract:** the artifact's `#i=` slug **must match** an `interactions.id`
the director created — otherwise the foreign key rejects the write. This is the one manual
coordination point between the claude.ai artifact and this repo.

**Security model:**
- `report_markdown` is stored as an **inert blob** (≤100 KB) and is **sanitized with
  DOMPurify only at render time** — never executed. The `#r=` payload is user-controllable,
  so treat it as untrusted anywhere it's displayed (admin viewer, submit preview).
- **RLS is the real gate:** a student can only write a row where
  `students.auth_user_id = auth.uid()`, so a spoofed `student_id` is rejected by the DB.
  Directors/admins read all reports; instructors read their own sections.

**Deferred:** where the analysis skill's *output* (per-section summaries) gets stored — a
new table or the `assignments.analysis_report` JSONB pattern. Not yet built.

## preflight-analyze Skill

Analyzes student submissions for a given assignment, writes suggested scores to Supabase, and generates per-instructor misconception reports.

**First time on a new machine? Run the setup wizard:**
```
/setup-preflight
```
This walks you through entering your Supabase credentials, writes your local config file,
and verifies the connection. Takes about 2 minutes.

**Manual setup** (if you prefer):
1. `cp .claude/skills/preflight-analyze/config.json.template ~/.claude/skills/preflight-analyze/config.json`
2. Fill in `supabase_url`, `supabase_service_key` (service_role key from Supabase dashboard → Project Settings → API), `textbook_base_path`, `default_course_id`
3. Set `textbook_base_path` to `{repo_root}/textbook-pdfs/{course_id}/` (see below)
4. The `config.json` is gitignored — never commit it

**Textbook PDFs** (`textbook-pdfs/` — gitignored, ~968 MB):
PDFs are NOT in the repo. Download from Teams → Files → `Core_Preflights_PDFs` and place in:
```
textbook-pdfs/
  phys-215/    ← Physics 215 lesson PDFs
  phys-110/    ← Physics 110 lesson PDFs
```
See `textbook-pdfs/README.md` for full instructions.

**Usage**: `/preflight-analyze [course_id] [assignment_id] [M|T]`

Example: `/preflight-analyze phys-215 preflight-2 M`

## Important Notes

- The anon key in `js/config.js` is protected by Supabase RLS — safe in a public repo
- The service key in `config.json` bypasses RLS — never commit it
- Scores are always written with `is_finalized: false`; instructors finalize in the Grade tab
- 3-state scoring: `full` (green), `warn` (yellow = full credit but wrong/vague), `zero` (red)
