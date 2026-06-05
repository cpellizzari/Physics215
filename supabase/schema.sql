-- Physics 215 Assignment System — Supabase Schema
-- Run this entire file in the Supabase SQL Editor (Project > SQL Editor > New Query)

-- ============================================================
-- INSTRUCTORS
-- Supabase Auth handles login; this table stores metadata.
-- After creating each instructor in Auth, insert a row here.
-- ============================================================
CREATE TABLE IF NOT EXISTS instructors (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  is_director BOOLEAN NOT NULL DEFAULT FALSE
);

-- ============================================================
-- SECTIONS
-- Configure once per semester. Format: [M|T][1|3|5][A-D]
-- ============================================================
CREATE TABLE IF NOT EXISTS sections (
  id TEXT PRIMARY KEY CHECK (id ~ '^[MT][135][A-D]$'),
  instructor_id UUID REFERENCES instructors(id) ON DELETE SET NULL
);

-- ============================================================
-- STUDENTS
-- Uploaded via CSV at semester start. IDs are 10-digit numbers
-- beginning with 3000. auth_user_id links to Supabase Auth account
-- (email = student_id@usafa.edu, default password = last 6 digits).
-- ============================================================
CREATE TABLE IF NOT EXISTS students (
  student_id BIGINT PRIMARY KEY
    CHECK (student_id >= 3000000000 AND student_id <= 3009999999),
  name TEXT NOT NULL,
  section_id TEXT REFERENCES sections(id) ON DELETE SET NULL,
  auth_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

-- ============================================================
-- ASSIGNMENTS
-- questions: JSON array — see SYSTEM_PLAN.md for structure.
-- reference_pdf: filename relative to textbook base path.
-- reference_pages: e.g. "45-52, 60" — used by Claude skill.
-- ============================================================
CREATE TABLE IF NOT EXISTS assignments (
  id TEXT PRIMARY KEY,  -- short slug, e.g. "preflight-1"
  title TEXT NOT NULL,
  description TEXT,
  due_date TIMESTAMPTZ NOT NULL,
  questions JSONB NOT NULL DEFAULT '[]',
  reference_pdf TEXT,
  reference_pages TEXT,
  is_published BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- RESPONSES
-- One row per student per assignment. Upserted on every save.
-- answers: { "q1": "text", "q2": "9.8", "q3": "C" }
-- ============================================================
CREATE TABLE IF NOT EXISTS responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id BIGINT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
  assignment_id TEXT NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
  answers JSONB NOT NULL DEFAULT '{}',
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(student_id, assignment_id)
);

-- Auto-update updated_at on upsert
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER responses_updated_at
  BEFORE UPDATE ON responses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- SCORES
-- Written by Claude skill (service key) as suggestions.
-- Finalized by instructor in admin UI.
-- question_scores: {
--   "q1": { "score": 8, "max": 10, "feedback": "..." },
--   ...
-- }
-- ============================================================
CREATE TABLE IF NOT EXISTS scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id BIGINT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
  assignment_id TEXT NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
  question_scores JSONB NOT NULL DEFAULT '{}',
  total_score NUMERIC,
  max_total NUMERIC,
  is_finalized BOOLEAN NOT NULL DEFAULT FALSE,
  graded_by UUID REFERENCES instructors(id) ON DELETE SET NULL,
  graded_at TIMESTAMPTZ,
  UNIQUE(student_id, assignment_id)
);
