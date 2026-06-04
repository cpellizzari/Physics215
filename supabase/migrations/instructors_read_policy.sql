-- Allow authenticated users (instructors) to read all instructor names.
-- Needed so the Instructors tab can list system admins across courses.

ALTER TABLE instructors ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "instructors_read_own" ON instructors;
DROP POLICY IF EXISTS "instructors_read_all" ON instructors;

-- Any logged-in instructor can read all instructor records (names are not sensitive)
CREATE POLICY "instructors_read_all" ON instructors
  FOR SELECT TO authenticated USING (true);

-- Each instructor can update their own record (e.g. name change)
CREATE POLICY "instructors_update_own" ON instructors
  FOR UPDATE TO authenticated USING (id = auth.uid());
