-- Allow authenticated users (instructors/admins) to insert and update sections
-- Sections are auto-created during roster upload; existing sections may be updated (e.g. instructor assignment)
CREATE POLICY "sections_insert_authenticated" ON sections
  FOR INSERT TO authenticated
  WITH CHECK (true);

CREATE POLICY "sections_update_authenticated" ON sections
  FOR UPDATE TO authenticated
  USING (true)
  WITH CHECK (true);
