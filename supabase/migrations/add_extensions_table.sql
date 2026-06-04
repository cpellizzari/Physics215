-- Extensions table: allows instructors to grant individual students
-- a later due date on a specific assignment.

CREATE TABLE IF NOT EXISTS extensions (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id        BIGINT      NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
  assignment_id     TEXT        NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
  extended_due_date TIMESTAMPTZ NOT NULL,
  granted_by        UUID        REFERENCES instructors(id),
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, assignment_id)
);

ALTER TABLE extensions ENABLE ROW LEVEL SECURITY;

-- Anyone (including the student page's anon key) can read extensions
CREATE POLICY "read_extensions" ON extensions
  FOR SELECT USING (true);

-- Authenticated instructors can insert, update, and delete extensions
CREATE POLICY "manage_extensions" ON extensions
  FOR ALL TO authenticated USING (true);
