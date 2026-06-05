-- Allow all authenticated instructors to read instructor_course_access.
-- Required for the Instructors tab to list all directors and instructors for a course.
-- Without this, only system admins appear (they are fetched from the instructors table directly).

ALTER TABLE instructor_course_access ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "course_access_read_authenticated" ON instructor_course_access;
CREATE POLICY "course_access_read_authenticated" ON instructor_course_access
  FOR SELECT TO authenticated
  USING (true);
