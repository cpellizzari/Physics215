-- Fix scores write policies so that directors can save and finalize grades
-- regardless of whether they were set up via instructor_course_access (new system)
-- or the legacy instructors.is_director flag (old system).
--
-- Root cause: migration 007 added INSERT/UPDATE policies that only checked
-- instructor_course_access.role = 'director'. Directors set up before that
-- table was in use have is_director = TRUE in instructors but no row in
-- instructor_course_access, so they fall through both the 007 policy and the
-- original "scores: instructor writes section" policy (which requires the
-- student to be in my_sections(), which is empty for directors with no
-- personally-assigned sections) → RLS error on save.

DROP POLICY IF EXISTS "scores: admin inserts all" ON scores;
CREATE POLICY "scores: admin inserts all"
  ON scores FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM instructors WHERE id = auth.uid() AND is_global_admin = TRUE)
    OR EXISTS (SELECT 1 FROM instructors WHERE id = auth.uid() AND is_director = TRUE)
    OR EXISTS (SELECT 1 FROM instructor_course_access WHERE instructor_id = auth.uid() AND role = 'director')
  );

DROP POLICY IF EXISTS "scores: admin updates all" ON scores;
CREATE POLICY "scores: admin updates all"
  ON scores FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM instructors WHERE id = auth.uid() AND is_global_admin = TRUE)
    OR EXISTS (SELECT 1 FROM instructors WHERE id = auth.uid() AND is_director = TRUE)
    OR EXISTS (SELECT 1 FROM instructor_course_access WHERE instructor_id = auth.uid() AND role = 'director')
  );
