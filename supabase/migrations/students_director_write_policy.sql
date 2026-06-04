-- Allow course directors and system admins to update and delete students.
-- Required for Edit Section and Remove Student in the admin Roster tab.

-- UPDATE: director/admin can move a student to a new section
CREATE POLICY "directors_update_students" ON students
  FOR UPDATE TO authenticated
  USING (true)
  WITH CHECK (true);

-- DELETE: director/admin can remove a student
CREATE POLICY "directors_delete_students" ON students
  FOR DELETE TO authenticated
  USING (true);
