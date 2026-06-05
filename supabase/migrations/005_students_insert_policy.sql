-- Allow authenticated users (instructors/admins) to insert students
-- UPDATE + DELETE were already covered by students_director_write_policy.sql
CREATE POLICY "students_insert_authenticated" ON students
  FOR INSERT TO authenticated
  WITH CHECK (true);
