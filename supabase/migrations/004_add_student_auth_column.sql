-- Add auth_user_id column to students table for Supabase Auth integration.
-- Links each student to a Supabase Auth account (email = student_id@usafa.edu).
-- Starts NULL for all existing students; populated by the provision-students edge function.
-- ON DELETE SET NULL: if the auth account is deleted, the student record is preserved.

ALTER TABLE students
  ADD COLUMN IF NOT EXISTS auth_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;
