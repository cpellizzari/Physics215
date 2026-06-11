-- Migration 012: Lesson interactions + student interaction reports
-- ============================================================
-- PURELY ADDITIVE. Creates two NEW tables and their policies only.
-- Does NOT alter, drop, or modify any existing table, column, policy, or row.
-- References existing objects read-only: students, instructors,
-- instructor_course_access, the update_updated_at() trigger fn, auth.uid().
--
-- Run in the Supabase SQL Editor (Project > SQL Editor > New Query).
-- ============================================================


-- ============================================================
-- INTERACTIONS
-- A "lesson interaction" = a Claude artifact a student works through.
-- id is the stable slug the artifact embeds in its submit link (e.g.
-- 'lesson-02-charge'); every student doing the same lesson shares it.
-- Deliberately separate from the assignments table.
-- ============================================================
CREATE TABLE IF NOT EXISTS interactions (
  id            TEXT PRIMARY KEY,                                   -- slug, e.g. 'lesson-02-charge'
  course_id     TEXT NOT NULL,                                      -- 'phys-215' | 'phys-110' (no courses table exists to FK)
  title         TEXT NOT NULL,
  description   TEXT,
  artifact_url  TEXT,                                              -- claude.ai artifact link students launch
  is_published  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE TRIGGER interactions_updated_at
  BEFORE UPDATE ON interactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX IF NOT EXISTS interactions_course_idx ON interactions (course_id);


-- ============================================================
-- PREFLIGHT_INTERACTION_REPORTS
-- One row per student per interaction. The student opens the artifact,
-- which packs a compressed Markdown report into the submit-page URL hash;
-- the page decodes it and upserts here. Course/section are NOT stored —
-- they're derived by joining to the student's own record.
-- ============================================================
CREATE TABLE IF NOT EXISTS preflight_interaction_reports (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  interaction_id  TEXT   NOT NULL REFERENCES interactions(id)     ON DELETE CASCADE,
  student_id      BIGINT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,

  -- Inert report blob; capped at 100 KB; sanitized only on render, never executed.
  report_markdown TEXT NOT NULL CHECK (length(report_markdown) <= 100000),

  -- Optional structured data for future querying (empty until used).
  report_data     JSONB,

  payload_bytes   INTEGER,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (student_id, interaction_id)
);

CREATE OR REPLACE TRIGGER preflight_interaction_reports_updated_at
  BEFORE UPDATE ON preflight_interaction_reports
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX IF NOT EXISTS pir_interaction_idx ON preflight_interaction_reports (interaction_id);


-- ============================================================
-- VIEW: reports joined to the student's section/course
-- Lets the analysis skill query "all reports for interaction X in section Y"
-- without writing the join each time. Service role bypasses RLS, so the
-- skill reads it directly.
-- ============================================================
CREATE OR REPLACE VIEW interaction_reports_by_section AS
  SELECT
    r.id,
    r.interaction_id,
    r.student_id,
    s.name        AS student_name,
    s.section_id,
    r.report_markdown,
    r.report_data,
    r.payload_bytes,
    r.created_at,
    r.updated_at
  FROM preflight_interaction_reports r
  JOIN students s ON s.student_id = r.student_id;


-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE interactions                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE preflight_interaction_reports  ENABLE ROW LEVEL SECURITY;

-- ── INTERACTIONS ──────────────────────────────────────────

-- Anyone may read PUBLISHED interactions (students browse the launcher page).
CREATE POLICY "interactions: public sees published"
  ON interactions FOR SELECT
  USING (is_published = TRUE);

-- Any instructor may read ALL interactions (incl. unpublished drafts).
CREATE POLICY "interactions: instructor sees all"
  ON interactions FOR SELECT
  USING (EXISTS (SELECT 1 FROM instructors WHERE id = auth.uid()));

-- Directors / global admins manage interactions. Same role test the
-- assignments + scores admin policies use (migrations 007/008/010).
CREATE POLICY "interactions: managers insert"
  ON interactions FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM instructors WHERE id = auth.uid() AND is_global_admin = TRUE)
    OR EXISTS (SELECT 1 FROM instructors WHERE id = auth.uid() AND is_director = TRUE)
    OR EXISTS (SELECT 1 FROM instructor_course_access WHERE instructor_id = auth.uid() AND role = 'director')
  );

CREATE POLICY "interactions: managers update"
  ON interactions FOR UPDATE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM instructors WHERE id = auth.uid() AND is_global_admin = TRUE)
    OR EXISTS (SELECT 1 FROM instructors WHERE id = auth.uid() AND is_director = TRUE)
    OR EXISTS (SELECT 1 FROM instructor_course_access WHERE instructor_id = auth.uid() AND role = 'director')
  );

CREATE POLICY "interactions: managers delete"
  ON interactions FOR DELETE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM instructors WHERE id = auth.uid() AND is_global_admin = TRUE)
    OR EXISTS (SELECT 1 FROM instructors WHERE id = auth.uid() AND is_director = TRUE)
    OR EXISTS (SELECT 1 FROM instructor_course_access WHERE instructor_id = auth.uid() AND role = 'director')
  );

-- ── PREFLIGHT_INTERACTION_REPORTS ─────────────────────────
-- The real gate: a student may only write a row bound to THEIR OWN auth
-- account. students.auth_user_id is populated at provisioning time, so
-- auth.uid() must match the student row — a spoofed student_id is rejected.

CREATE POLICY "pir: student inserts own"
  ON preflight_interaction_reports FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM students s
      WHERE s.student_id = preflight_interaction_reports.student_id
        AND s.auth_user_id = auth.uid()
    )
  );

CREATE POLICY "pir: student updates own"
  ON preflight_interaction_reports FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM students s
      WHERE s.student_id = preflight_interaction_reports.student_id
        AND s.auth_user_id = auth.uid()
    )
  );

CREATE POLICY "pir: student reads own"
  ON preflight_interaction_reports FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM students s
      WHERE s.student_id = preflight_interaction_reports.student_id
        AND s.auth_user_id = auth.uid()
    )
  );

-- Instructors read reports for students in their own sections.
CREATE POLICY "pir: instructor reads section"
  ON preflight_interaction_reports FOR SELECT
  USING (
    is_instructor()
    AND student_id IN (
      SELECT s.student_id FROM students s
      WHERE s.section_id IN (SELECT section_id FROM my_sections())
    )
  );

-- Directors / global admins read all reports.
CREATE POLICY "pir: admin reads all"
  ON preflight_interaction_reports FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM instructors WHERE id = auth.uid() AND is_global_admin = TRUE)
    OR EXISTS (SELECT 1 FROM instructors WHERE id = auth.uid() AND is_director = TRUE)
    OR EXISTS (SELECT 1 FROM instructor_course_access WHERE instructor_id = auth.uid() AND role = 'director')
  );
