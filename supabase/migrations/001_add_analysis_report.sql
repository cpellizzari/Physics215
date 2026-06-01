-- Migration 001: Add analysis_report column to assignments
-- Run in Supabase SQL Editor → New Query
-- This stores the per-question summary paragraphs written by the physics215-analyze skill.

ALTER TABLE assignments
  ADD COLUMN IF NOT EXISTS analysis_report JSONB;

-- Structure written by the skill:
-- {
--   "generated_at": "2026-06-01T...",
--   "questions": {
--     "q1": { "summary": "Paragraph describing class understanding and misconceptions..." },
--     "q2": { "summary": "..." }
--   }
-- }
