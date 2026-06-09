-- Allow course directors and system admins to UPDATE the role column on
-- instructor_course_access. This lets the Instructors tab change a person's
-- role (instructor ↔ course director) without needing the service key.
-- The existing directors_delete_course_access policy covers DELETE;
-- this mirrors the same scoping for UPDATE.

CREATE POLICY "directors_update_course_access" ON instructor_course_access
  FOR UPDATE TO authenticated
  USING (
    course_id IN (
      SELECT course_id FROM instructor_course_access
      WHERE instructor_id = auth.uid() AND role = 'director'
    )
    OR EXISTS (
      SELECT 1 FROM instructors WHERE id = auth.uid() AND is_global_admin = true
    )
  )
  WITH CHECK (
    course_id IN (
      SELECT course_id FROM instructor_course_access
      WHERE instructor_id = auth.uid() AND role = 'director'
    )
    OR EXISTS (
      SELECT 1 FROM instructors WHERE id = auth.uid() AND is_global_admin = true
    )
  );
