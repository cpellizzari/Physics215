-- Update sections.id CHECK constraint to allow periods 1, 3, and 5
-- (previously allowed 1, 3, and 6; also expand letters from A-C to A-D)

ALTER TABLE sections DROP CONSTRAINT IF EXISTS sections_id_check;
ALTER TABLE sections ADD CONSTRAINT sections_id_check
  CHECK (id ~ '^[MT][135][A-D]$');
