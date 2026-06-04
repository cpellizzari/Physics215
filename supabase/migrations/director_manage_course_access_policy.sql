-- Allow course directors to delete instructor_course_access entries for their course.
-- This lets the admin page remove an instructor's access without needing the service key.

CREATE POLICY "directors_delete_course_access" ON instructor_course_access
  FOR DELETE TO authenticated
  USING (
    course_id IN (
      SELECT course_id FROM instructor_course_access
      WHERE instructor_id = auth.uid() AND role = 'director'
    )
    OR EXISTS (
      SELECT 1 FROM instructors WHERE id = auth.uid() AND is_global_admin = true
    )
  );
