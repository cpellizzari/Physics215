-- Physics 215 — Test Seed Data (Preflight 1 / Section M1A)
-- Run AFTER schema.sql and rls.sql.
-- Director UUID: 6ad3ad7e-0a5b-4512-b9be-24673cbb0160 (Casey Pellizzari)

-- ============================================================
-- 1. Section M1A (course director teaches it for the test)
-- ============================================================
INSERT INTO sections (id, instructor_id)
VALUES ('M1A', '6ad3ad7e-0a5b-4512-b9be-24673cbb0160')
ON CONFLICT (id) DO UPDATE SET instructor_id = EXCLUDED.instructor_id;

-- ============================================================
-- 2. Test students (made-up 3000xxxxxx IDs)
-- ============================================================
INSERT INTO students (student_id, name, section_id) VALUES
  (3000000001, 'Tyler Hardy', 'M1A'),
  (3000000002, 'Tyler Jones', 'M1A')
ON CONFLICT (student_id) DO UPDATE
  SET name = EXCLUDED.name, section_id = EXCLUDED.section_id;

-- ============================================================
-- 3. Preflight 1 assignment
--    Questions pulled from Gradescope course 1319967 assignment 8189939
-- ============================================================
INSERT INTO assignments (id, title, description, due_date, questions, is_published)
VALUES (
  'preflight-1',
  'Preflight 1',
  'Complete before the first lesson. Answer honestly — this is for your benefit.',
  '2026-06-03 20:45:00+00',
  '[
    {
      "id": "q1",
      "type": "free_response",
      "text": "How much time did you spend reading the book in preparation for this lesson?",
      "points": 0.1
    },
    {
      "id": "q2",
      "type": "free_response",
      "text": "What did you find most confusing or most interesting about the reading? Be specific and thorough in your discussion.",
      "points": 0.9
    },
    {
      "id": "q3",
      "type": "free_response",
      "text": "What happens when a charged insulator is placed near an uncharged metallic object? Specifically, do they attract or repel and why?",
      "points": 1.0,
      "expected_response": "They attract. The charged insulator induces polarization in the metal: free electrons in the conductor redistribute in response to the external charge, creating an opposite charge on the near side. This induced dipole results in a net attractive force even though the metal has zero net charge overall."
    }
  ]'::jsonb,
  true
)
ON CONFLICT (id) DO UPDATE
  SET title = EXCLUDED.title,
      description = EXCLUDED.description,
      due_date = EXCLUDED.due_date,
      questions = EXCLUDED.questions,
      is_published = EXCLUDED.is_published;

-- ============================================================
-- 4. Sample responses (from Gradescope submissions)
-- ============================================================
INSERT INTO responses (student_id, assignment_id, answers) VALUES
(
  3000000001,
  'preflight-1',
  '{
    "q1": "30 minutes.",
    "q2": "Testing a long answer about what I was confused about.",
    "q3": "They attract because the electrons are free to move in a conductor, and it will polarize to be attracted to the conductor."
  }'::jsonb
),
(
  3000000002,
  'preflight-1',
  '{
    "q1": "I hate the book - it makes me sick to my stomach when I try to read it.",
    "q2": "See Q1 - I didn''t read.",
    "q3": ""
  }'::jsonb
)
ON CONFLICT (student_id, assignment_id) DO UPDATE
  SET answers = EXCLUDED.answers, updated_at = NOW();
