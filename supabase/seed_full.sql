-- Physics 215 — Full Test Data Seed
-- Run AFTER schema.sql, rls.sql, and seed_test.sql.
--
-- Before running:
--   1. Create Tyler Jones's account in Supabase Auth → Users → Add User
--      Email: tyler.jones@afacademy.af.edu  Password: (anything)
--   2. Copy his UUID and replace 52b48755-01a5-479e-9bfa-eeeedce12742 below.
--   3. Tyler Jones (3000000002) was a test student — this script removes him.
--
-- Replace: 52b48755-01a5-479e-9bfa-eeeedce12742  →  UUID from Supabase Auth for Tyler Jones
-- Casey's UUID is already in the DB: 6ad3ad7e-0a5b-4512-b9be-24673cbb0160

-- ============================================================
-- 0. Remove test students (Tyler Hardy was fake; Tyler Jones becomes instructor)
-- ============================================================
DELETE FROM responses WHERE student_id IN (3000000001, 3000000002);
DELETE FROM scores    WHERE student_id IN (3000000001, 3000000002);
DELETE FROM students  WHERE student_id IN (3000000001, 3000000002);

-- ============================================================
-- 1. Register Tyler Jones as instructor
-- ============================================================
INSERT INTO instructors (id, name, is_director)
VALUES ('52b48755-01a5-479e-9bfa-eeeedce12742', 'Tyler Jones', FALSE)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

-- ============================================================
-- 2. Sections  (Casey: M1A, M1B  |  Tyler Jones: T3A, T3B)
-- ============================================================
INSERT INTO sections (id, instructor_id) VALUES
  ('M1A', '6ad3ad7e-0a5b-4512-b9be-24673cbb0160'),
  ('M1B', '6ad3ad7e-0a5b-4512-b9be-24673cbb0160'),
  ('T3A', '52b48755-01a5-479e-9bfa-eeeedce12742'),
  ('T3B', '52b48755-01a5-479e-9bfa-eeeedce12742')
ON CONFLICT (id) DO UPDATE SET instructor_id = EXCLUDED.instructor_id;

-- ============================================================
-- 3. Students  (IDs 3000001001–3000001032, 8 per section)
-- ============================================================
INSERT INTO students (student_id, name, section_id) VALUES
-- Section M1A
  (3000001001, 'Alex Carter',    'M1A'),
  (3000001002, 'Jordan Blake',   'M1A'),
  (3000001003, 'Morgan Ellis',   'M1A'),
  (3000001004, 'Riley Nguyen',   'M1A'),
  (3000001005, 'Quinn Foster',   'M1A'),
  (3000001006, 'Avery Brooks',   'M1A'),
  (3000001007, 'Taylor Kim',     'M1A'),
  (3000001008, 'Drew Castillo',  'M1A'),
-- Section M1B
  (3000001011, 'Sam Mitchell',   'M1B'),
  (3000001012, 'Casey Torres',   'M1B'),
  (3000001013, 'Reese Walker',   'M1B'),
  (3000001014, 'Jamie Lee',      'M1B'),
  (3000001015, 'Parker Owens',   'M1B'),
  (3000001016, 'Robin Hayes',    'M1B'),
  (3000001017, 'Blake Adams',    'M1B'),
  (3000001018, 'Cameron West',   'M1B'),
-- Section T3A
  (3000001021, 'Dakota Rivera',  'T3A'),
  (3000001022, 'Skyler Patel',   'T3A'),
  (3000001023, 'Finley Grant',   'T3A'),
  (3000001024, 'Emery Shaw',     'T3A'),
  (3000001025, 'Hayden Cole',    'T3A'),
  (3000001026, 'Rowan Jensen',   'T3A'),
  (3000001027, 'Logan Stone',    'T3A'),
  (3000001028, 'Peyton Ward',    'T3A'),
-- Section T3B
  (3000001031, 'Kendall Ross',   'T3B'),
  (3000001032, 'Sutton Bell',    'T3B'),
  (3000001033, 'Harlow Cruz',    'T3B'),
  (3000001034, 'Elliot Simmons', 'T3B'),
  (3000001035, 'Sage Turner',    'T3B'),
  (3000001036, 'Remy Hughes',    'T3B'),
  (3000001037, 'Marlowe Price',  'T3B'),
  (3000001038, 'Indigo Cooper',  'T3B')
ON CONFLICT (student_id) DO UPDATE
  SET name = EXCLUDED.name, section_id = EXCLUDED.section_id;

-- Keep Tyler Jones (3000000002) as M1A student from seed_test.sql

-- ============================================================
-- 4. Responses for Preflight 1
--    Varied answers showing realistic physics engagement
-- ============================================================

-- ── M1A students ──
INSERT INTO responses (student_id, assignment_id, answers) VALUES

(3000001001, 'preflight-1', '{
  "q1": "About 45 minutes.",
  "q2": "I found the section on electric fields most interesting. The idea that a charged object can exert force on another object without touching it seems counterintuitive at first, but the field concept makes it click.",
  "q3": "They attract. The charged insulator creates an electric field that causes the free electrons in the metal to move toward it, leaving the far side positive. This separation of charge causes a net attraction."
}'::jsonb),

(3000001002, 'preflight-1', '{
  "q1": "30 minutes.",
  "q2": "I was confused by Coulomb''s law — specifically when there are multiple charges. Do you just add up all the forces? Also not sure how the constant k relates to permittivity of free space.",
  "q3": "They attract because the metal gets polarized. The electrons bunch up on the near side and the positive ions stay, so the near side is attracted to the insulator."
}'::jsonb),

(3000001003, 'preflight-1', '{
  "q1": "1 hour.",
  "q2": "Most confusing was the difference between conductors and insulators at the atomic level. I understand conductors have free electrons but I''m not sure how many are really free per atom.",
  "q3": "They attract. The insulator has a net charge and when it comes near the metal, it pushes or pulls the free electrons in the metal so that one side of the metal has the opposite charge. Opposite charges attract."
}'::jsonb),

(3000001004, 'preflight-1', '{
  "q1": "20 minutes.",
  "q2": "The concept of electric flux was interesting but I don''t fully understand it yet. I get that it measures how much field passes through a surface but the math feels abstract.",
  "q3": "They repel. Both objects have charges so they push away from each other."
}'::jsonb),

(3000001005, 'preflight-1', '{
  "q1": "About 40 minutes.",
  "q2": "I found the historical context about Coulomb''s experiments interesting. The section on superposition was confusing - I''m not sure whether you add force vectors or just magnitudes.",
  "q3": "They attract. Even though the metal is uncharged overall, the charged insulator induces a charge separation in the metal. The closer side gets the opposite charge and since opposites attract, there is a net pull."
}'::jsonb),

(3000001006, 'preflight-1', '{
  "q1": "I skimmed it, maybe 15 minutes.",
  "q2": "I didn''t read it carefully enough to have specific questions.",
  "q3": "Attract, because of static electricity."
}'::jsonb),

(3000001007, 'preflight-1', '{
  "q1": "50 minutes.",
  "q2": "What confused me most was the relationship between electric field lines and force. I know field lines point in the direction of force on a positive charge but I got turned around when thinking about negative charges.",
  "q3": "They attract. The process is called induction. The free electrons in the conductor redistribute so the face closest to the charged insulator has opposite charge. Since the attraction to the near face is stronger than the repulsion from the far face, there is a net attractive force."
}'::jsonb),

(3000001008, 'preflight-1', '{
  "q1": "25 minutes.",
  "q2": "The part about quantization of charge was interesting - that all charge comes in multiples of e = 1.6e-19 C. Also wasn''t sure what determines whether an object is a conductor or insulator.",
  "q3": "They attract because the electrons in the metal can move freely and they rearrange so the metal is attracted."
}'::jsonb),

-- ── M1B students ──
(3000001011, 'preflight-1', '{
  "q1": "35 minutes.",
  "q2": "Most interesting was learning that the electric force follows an inverse square law just like gravity. I''m curious whether this is a coincidence or has a deeper reason.",
  "q3": "They attract. The charged insulator polarizes the metal by causing electrons to shift toward or away from the insulator. The side closer to the insulator has the opposite sign charge, causing attraction."
}'::jsonb),

(3000001012, 'preflight-1', '{
  "q1": "45 minutes.",
  "q2": "I was confused by the distinction between charge distribution on conductors vs insulators. For conductors charges go to the surface, but why exactly? And what happens on a sharp point?",
  "q3": "They would attract. When the charged insulator comes near, it induces a charge on the near side of the metal through polarization of the free electrons. The net force is attractive even though the metal has no net charge."
}'::jsonb),

(3000001013, 'preflight-1', '{
  "q1": "1 hour 15 minutes.",
  "q2": "The most confusing part was Gauss''s law. I sort of understand the concept but I''m not sure when to use it versus just Coulomb''s law directly. The examples with spherical symmetry made sense but other geometries are less clear.",
  "q3": "They attract. Free electrons in the metallic object move to the side nearest the insulator if the insulator is positively charged, making that side negative. The negative side is closer and the attractive force is stronger than the repulsive force from the far side."
}'::jsonb),

(3000001014, 'preflight-1', '{
  "q1": "I read for about 20 minutes but got distracted.",
  "q2": "Not sure yet - didn''t finish the reading.",
  "q3": ""
}'::jsonb),

(3000001015, 'preflight-1', '{
  "q1": "30 minutes.",
  "q2": "Found the concept of test charges confusing - we define electric field using a small positive test charge, but does the test charge change the field we''re trying to measure?",
  "q3": "They attract. The insulator''s charge induces polarization in the conductor - the free electrons redistribute creating a charge imbalance. The near side has opposite charge to the insulator so they pull toward each other."
}'::jsonb),

(3000001016, 'preflight-1', '{
  "q1": "About 1 hour.",
  "q2": "The reading was interesting overall. I found the part about insulators and conductors most interesting because I hadn''t thought about it at the atomic level before. Most confusing was the vector addition of electric fields from multiple charges.",
  "q3": "Attract. The metal becomes polarized near the insulator because the free electrons can move. One side of the metal will be oppositely charged to the insulator, leading to a net attractive force."
}'::jsonb),

(3000001017, 'preflight-1', '{
  "q1": "10 minutes.",
  "q2": "Did not read thoroughly.",
  "q3": "I think they repel since both have charges."
}'::jsonb),

(3000001018, 'preflight-1', '{
  "q1": "40 minutes.",
  "q2": "I was most confused about the direction of electric field vectors when there are multiple source charges. Specifically, when you have both positive and negative charges nearby, how do you determine which dominates?",
  "q3": "They attract. Even though the metal doesn''t have a net charge, the insulator causes polarization. Electrons shift so that the near face of the metal has charge opposite to the insulator. The near attraction dominates over the far repulsion."
}'::jsonb),

-- ── T3A students ──
(3000001021, 'preflight-1', '{
  "q1": "45 minutes.",
  "q2": "The most interesting thing was how Coulomb was able to measure something as small as electric force with a torsion balance. The most confusing was understanding how the principle of superposition works in practice with more than two charges.",
  "q3": "They attract due to induction. The charged insulator causes free electrons in the conductor to shift, polarizing it. The side closer to the insulator becomes oppositely charged, and since the attractive force decreases with distance squared, the attraction is stronger than the repulsion from the far side."
}'::jsonb),

(3000001022, 'preflight-1', '{
  "q1": "1 hour.",
  "q2": "I found the connection between electric field and potential energy interesting but I''m confused about the sign conventions. When is the potential energy positive vs negative?",
  "q3": "They attract. The metal polarizes - free electrons redistribute so one side is closer to the sign of the insulator and the other side is the same sign. The opposite side is closer so the force is attractive."
}'::jsonb),

(3000001023, 'preflight-1', '{
  "q1": "2 hours - went deep on it.",
  "q2": "Most interesting was thinking about what really is charge at a fundamental level. Most confusing was the units - coulombs, newtons per coulomb, joules per coulomb. Keeping track of the units in problems.",
  "q3": "They attract each other. The reason is that the charged insulator creates an electric field that causes the free electrons in the conductor to migrate toward the insulator if the insulator is positively charged. This leaves the near side negative and the far side positive. Because electric force goes as 1/r^2, the attraction to the near face dominates, giving a net attractive force."
}'::jsonb),

(3000001024, 'preflight-1', '{
  "q1": "About 30 minutes.",
  "q2": "The reading was okay. I found the examples helpful but found the section on Gauss''s law hard to follow.",
  "q3": "They attract I think. Something about the charges in the metal rearranging."
}'::jsonb),

(3000001025, 'preflight-1', '{
  "q1": "15 minutes.",
  "q2": ".",
  "q3": ""
}'::jsonb),

(3000001026, 'preflight-1', '{
  "q1": "45 minutes.",
  "q2": "I found charge quantization interesting - the fact that charge can only exist in integer multiples of the elementary charge. What I found confusing is the concept of charge density - surface charge density vs volume charge density.",
  "q3": "They attract. The uncharged metal gets polarized by induction - the free electrons in the metal shift in response to the external electric field from the insulator, making one side negative and the other side positive. The force is attractive because the like charges are further away."
}'::jsonb),

(3000001027, 'preflight-1', '{
  "q1": "1 hour 30 minutes.",
  "q2": "The most interesting was the section on how Millikan measured the charge of an electron. Most confusing was working through the vector components of electric field when charges are arranged in 2D.",
  "q3": "Attract. The metal is polarized by the electric field of the insulator. The free electrons in the conductor move to minimize energy, creating an induced charge on the surface. The side closer to the insulator has the opposite sign, so they attract."
}'::jsonb),

(3000001028, 'preflight-1', '{
  "q1": "Zero, I didn''t have time.",
  "q2": "See above.",
  "q3": ""
}'::jsonb),

-- ── T3B students ──
(3000001031, 'preflight-1', '{
  "q1": "30 minutes.",
  "q2": "Most interesting: the fact that objects can have induced charges without transferring charge - just by proximity. Confusing: the formula for electric potential - how is it different from electric field?",
  "q3": "They attract. The insulator polarizes the metal. The free electrons in the metal move toward (or away from) the insulator creating opposite charges on the near side. Net force is attractive."
}'::jsonb),

(3000001032, 'preflight-1', '{
  "q1": "About 45 min.",
  "q2": "What I found most confusing was understanding when to model charge as a point charge versus a distributed charge. When is the approximation valid?",
  "q3": "They attract because the charged insulator causes polarization in the conductor. Electrons in the metal redistribute so the near surface has opposite charge to the insulator. Like charges repel and opposite charges attract, so there is a net attraction."
}'::jsonb),

(3000001033, 'preflight-1', '{
  "q1": "1 hour.",
  "q2": "The most confusing was the right hand rule for electric field direction. Also I''m not sure if the electric field inside a conductor is really zero when there are external charges nearby.",
  "q3": "They attract. When the charged insulator is brought close, the electrons in the metallic object redistribute. If the insulator is positive, electrons cluster on the near side making it negative. The metal has zero net charge but has a charge imbalance that causes net attraction."
}'::jsonb),

(3000001034, 'preflight-1', '{
  "q1": "45 minutes.",
  "q2": "What I found most interesting was the shell theorem - that a uniform shell of charge acts as if all the charge is at the center. I wasn''t expecting that result from Gauss''s law.",
  "q3": "They attract. This is an example of electrostatic induction. The charged insulator polarizes the metallic object by displacing electrons in the conductor. The side facing the insulator acquires an opposite charge, resulting in a net attractive force even though the metal has no overall charge."
}'::jsonb),

(3000001035, 'preflight-1', '{
  "q1": "I read for 25 minutes.",
  "q2": "I found the notation confusing - using E for electric field and also using E for energy in other contexts.",
  "q3": "Repel - I think if the insulator is charged and the metal is neutral they repel."
}'::jsonb),

(3000001036, 'preflight-1', '{
  "q1": "1 hour.",
  "q2": "The most confusing was why electric field lines never cross. I get the reasoning but it took me a minute. Most interesting was learning that you can shield electronics with a Faraday cage.",
  "q3": "They attract. Because the metal has free electrons that can move around, when you bring a charged insulator close the electrons redistribute. One face of the metal ends up with opposite charge to the insulator, so it attracts."
}'::jsonb),

(3000001037, 'preflight-1', '{
  "q1": "20 minutes.",
  "q2": "I found this reading dense. Not sure what I should focus on.",
  "q3": "I''m not sure. Maybe they attract?"
}'::jsonb),

(3000001038, 'preflight-1', '{
  "q1": "55 minutes.",
  "q2": "Most interesting: how a Faraday cage blocks electric fields - the charges redistribute on the outside and cancel the field inside. Most confusing: the relationship between Coulomb''s law and Gauss''s law - are they saying the same thing in different forms?",
  "q3": "They attract. The charged insulator creates an electric field that polarizes the metal conductor. Free electrons migrate to the surface nearest the insulator, creating an opposite charge there. Since the attractive force between unlike charges is stronger at shorter range, there is a net attraction."
}'::jsonb)

ON CONFLICT (student_id, assignment_id) DO UPDATE
  SET answers = EXCLUDED.answers, updated_at = NOW();

-- ============================================================
-- 5. Responses for Preflight 2
--    Replace 'preflight-2' below with the actual assignment ID
--    if the user created it with a different slug.
--    Responses intentionally varied: some strong, some weak.
-- ============================================================

-- Note: Only insert if preflight-2 exists in your assignments table.
-- If your second preflight has a different ID, replace 'preflight-2' below.

-- Uncomment and run once you know the preflight-2 assignment ID:
/*
INSERT INTO responses (student_id, assignment_id, answers) VALUES
  (3000001001, 'preflight-2', '{"q1": "30 min.", "q2": "Confused about Newton 2nd law sign conventions.", "q3": "Net force equals mass times acceleration. Direction of acceleration is same as direction of net force."}'::jsonb),
  (3000001002, 'preflight-2', '{"q1": "45 min.", "q2": "Interesting that inertia doesn t have units of its own really.", "q3": "If net force is zero, the object stays at rest or moves at constant velocity - Newton 1st law."}'::jsonb),
  (3000001011, 'preflight-2', '{"q1": "1 hour.", "q2": "The difference between mass and weight was confusing at first.", "q3": "F=ma so acceleration is in same direction as the net force applied."}'::jsonb),
  (3000001021, 'preflight-2', '{"q1": "40 min.", "q2": "Most interesting was the tension in ropes and how it transmits force.", "q3": "Newton 2nd law: the net force on an object equals its mass times its acceleration. This is a vector equation."}'::jsonb)
ON CONFLICT (student_id, assignment_id) DO UPDATE
  SET answers = EXCLUDED.answers, updated_at = NOW();
*/
