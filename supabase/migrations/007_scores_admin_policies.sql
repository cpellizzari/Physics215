-- Admins and directors need to read, write, and finalize ALL scores —
-- not just scores for sections they personally teach.
-- The existing "scores: instructor *" policies (from rls.sql) use my_sections()
-- which returns empty for users with no assigned sections, silently blocking saves.

-- SELECT: admins/directors see all scores
CREATE POLICY "scores: admin reads all"
  ON scores FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM instructors WHERE id = auth.uid() AND is_global_admin = TRUE)
    OR EXISTS (SELECT 1 FROM instructor_course_access WHERE instructor_id = auth.uid() AND role = 'director')
  );

-- INSERT: admins/directors can create score rows for any student
CREATE POLICY "scores: admin inserts all"
  ON scores FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM instructors WHERE id = auth.uid() AND is_global_admin = TRUE)
    OR EXISTS (SELECT 1 FROM instructor_course_access WHERE instructor_id = auth.uid() AND role = 'director')
  );

-- UPDATE: admins/directors can update (including finalize) any score row
CREATE POLICY "scores: admin updates all"
  ON scores FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM instructors WHERE id = auth.uid() AND is_global_admin = TRUE)
    OR EXISTS (SELECT 1 FROM instructor_course_access WHERE instructor_id = auth.uid() AND role = 'director')
  );
