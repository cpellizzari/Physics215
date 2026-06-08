-- Add an optional figure URL to assignments.
-- Used to display a diagram or illustration above all questions on an assignment.
-- Per-question figures are stored inside the questions JSONB (no migration needed).
ALTER TABLE assignments ADD COLUMN IF NOT EXISTS figure_url TEXT;
