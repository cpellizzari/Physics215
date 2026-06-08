-- The original "assignments: director creates/updates" policies (from rls.sql) use
-- is_director() which checks instructors.is_director = TRUE — not the newer
-- instructor_course_access role system. This blocks global admins and course
-- directors added via instructor_course_access from creating or editing assignments.

CREATE POLICY "assignments: admin creates"
  ON assignments FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM instructors WHERE id = auth.uid() AND is_global_admin = TRUE)
    OR EXISTS (SELECT 1 FROM instructor_course_access WHERE instructor_id = auth.uid() AND role = 'director')
  );

CREATE POLICY "assignments: admin updates"
  ON assignments FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM instructors WHERE id = auth.uid() AND is_global_admin = TRUE)
    OR EXISTS (SELECT 1 FROM instructor_course_access WHERE instructor_id = auth.uid() AND role = 'director')
  );
