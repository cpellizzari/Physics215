-- Physics 215 — Row Level Security Policies
-- Run this after schema.sql in the Supabase SQL Editor.
-- Service role (used by Claude skill + admin operations) bypasses all RLS automatically.

-- Enable RLS on every table
ALTER TABLE instructors  ENABLE ROW LEVEL SECURITY;
ALTER TABLE sections     ENABLE ROW LEVEL SECURITY;
ALTER TABLE students     ENABLE ROW LEVEL SECURITY;
ALTER TABLE assignments  ENABLE ROW LEVEL SECURITY;
ALTER TABLE responses    ENABLE ROW LEVEL SECURITY;
ALTER TABLE scores       ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- Helper: check if current auth user is an instructor
-- ============================================================
CREATE OR REPLACE FUNCTION is_instructor()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER AS $$
  SELECT EXISTS (SELECT 1 FROM instructors WHERE id = auth.uid());
$$;

-- Helper: check if current auth user is the course director
CREATE OR REPLACE FUNCTION is_director()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER AS $$
  SELECT EXISTS (SELECT 1 FROM instructors WHERE id = auth.uid() AND is_director = TRUE);
$$;

-- Helper: get sections belonging to current instructor
CREATE OR REPLACE FUNCTION my_sections()
RETURNS TABLE(section_id TEXT) LANGUAGE sql SECURITY DEFINER AS $$
  SELECT id FROM sections WHERE instructor_id = auth.uid();
$$;

-- ============================================================
-- INSTRUCTORS
-- ============================================================
CREATE POLICY "instructors: read own record"
  ON instructors FOR SELECT
  USING (id = auth.uid());

CREATE POLICY "instructors: director reads all"
  ON instructors FOR SELECT
  USING (is_director());

-- ============================================================
-- SECTIONS
-- ============================================================
CREATE POLICY "sections: anyone can read"
  ON sections FOR SELECT
  USING (TRUE);

CREATE POLICY "sections: director manages"
  ON sections FOR ALL
  USING (is_director())
  WITH CHECK (is_director());

-- ============================================================
-- STUDENTS
-- Anon users can look up a student by ID (for "Welcome" display).
-- Only service role (roster uploads) can write.
-- ============================================================
CREATE POLICY "students: public read"
  ON students FOR SELECT
  USING (TRUE);

-- ============================================================
-- ASSIGNMENTS
-- Published assignments visible to everyone.
-- Instructors see all (including unpublished).
-- Only director creates/edits.
-- ============================================================
CREATE POLICY "assignments: public sees published"
  ON assignments FOR SELECT
  USING (is_published = TRUE);

CREATE POLICY "assignments: instructor sees all"
  ON assignments FOR SELECT
  USING (is_instructor());

CREATE POLICY "assignments: director creates"
  ON assignments FOR INSERT
  WITH CHECK (is_director());

CREATE POLICY "assignments: director updates"
  ON assignments FOR UPDATE
  USING (is_director());

-- ============================================================
-- RESPONSES
-- Students submit and read back their own responses.
-- Instructors read responses for their sections' students.
-- No auth JWT on student side — application enforces student_id ownership.
-- ============================================================

-- Anon can insert a response (student_id must exist in students table)
CREATE POLICY "responses: anyone inserts"
  ON responses FOR INSERT
  WITH CHECK (
    student_id IN (SELECT student_id FROM students)
  );

-- Anon can update their own response before deadline
CREATE POLICY "responses: anon updates own"
  ON responses FOR UPDATE
  USING (
    student_id IN (SELECT student_id FROM students)
    AND (
      SELECT due_date > NOW()
      FROM assignments
      WHERE id = assignment_id
    )
  );

-- Anon can read responses (frontend filters by student_id in URL param)
CREATE POLICY "responses: anon reads"
  ON responses FOR SELECT
  USING (TRUE);

-- Instructors read responses for their sections
CREATE POLICY "responses: instructor reads section"
  ON responses FOR SELECT
  USING (
    is_instructor()
    AND student_id IN (
      SELECT s.student_id FROM students s
      WHERE s.section_id IN (SELECT section_id FROM my_sections())
    )
  );

-- ============================================================
-- SCORES
-- Students see their own finalized scores.
-- Instructors manage scores for their sections.
-- ============================================================
CREATE POLICY "scores: student reads finalized"
  ON scores FOR SELECT
  USING (is_finalized = TRUE);

CREATE POLICY "scores: instructor reads section"
  ON scores FOR SELECT
  USING (
    is_instructor()
    AND student_id IN (
      SELECT s.student_id FROM students s
      WHERE s.section_id IN (SELECT section_id FROM my_sections())
    )
  );

CREATE POLICY "scores: instructor writes section"
  ON scores FOR INSERT
  WITH CHECK (
    is_instructor()
    AND student_id IN (
      SELECT s.student_id FROM students s
      WHERE s.section_id IN (SELECT section_id FROM my_sections())
    )
  );

CREATE POLICY "scores: instructor updates section"
  ON scores FOR UPDATE
  USING (
    is_instructor()
    AND student_id IN (
      SELECT s.student_id FROM students s
      WHERE s.section_id IN (SELECT section_id FROM my_sections())
    )
  );
