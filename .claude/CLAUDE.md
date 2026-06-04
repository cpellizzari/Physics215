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
| `js/config.js` | Supabase URL + anon key (safe to commit) |
| `css/styles.css` | Shared styles |
| `supabase/seed_full.sql` | Test data for local development |

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

## Section Naming Convention

`[M|T][1|3|6][A-D]` — M = M-day, T = T-day; number = period; letter = section within period.
M-day sections use `due_date_m` on assignments; T-day sections use `due_date_t`.

## preflight-analyze Skill

Analyzes student submissions for a given assignment, writes suggested scores to Supabase, and generates per-instructor misconception reports.

**Setup** (one-time per instructor):
1. `cp .claude/skills/preflight-analyze/config.json.template .claude/skills/preflight-analyze/config.json`
2. Fill in `supabase_url`, `supabase_service_key` (get from course director), `textbook_base_path`, `default_course_id`
3. The `config.json` is gitignored — never commit it

**Usage**: `/preflight-analyze [course_id] [assignment_id] [M|T]`

Example: `/preflight-analyze phys-215 preflight-2 M`

## Important Notes

- The anon key in `js/config.js` is protected by Supabase RLS — safe in a public repo
- The service key in `config.json` bypasses RLS — never commit it
- Scores are always written with `is_finalized: false`; instructors finalize in the Grade tab
- 3-state scoring: `full` (green), `warn` (yellow = full credit but wrong/vague), `zero` (red)
