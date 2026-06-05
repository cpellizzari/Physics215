#!/usr/bin/env node
// Physics 215 — Test Response + Score Generator
// Usage: node scripts/test-data/seed-test-data.js
//
// Prereqs:
//   1. Run migration 003 + 004 in Supabase SQL editor
//   2. Upload phys215-test-roster.csv via admin panel
//   3. Provision student accounts via admin Roster tab
//
// This script inserts fake responses + unfinalized scores for
// preflight-1 and preflight-2 for all phys-215 students.
//
// Reads config from: ~/.claude/skills/preflight-analyze/config.json
//   Required keys: supabase_url, supabase_service_key

'use strict';

const fs   = require('fs');
const path = require('path');

// ── Load config ──────────────────────────────────────────────
const configPath = path.join(
  process.env.HOME || process.env.USERPROFILE,
  '.claude', 'skills', 'preflight-analyze', 'config.json'
);

let config;
try {
  config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
} catch (e) {
  console.error('Could not read config.json:', e.message);
  console.error('Expected path:', configPath);
  process.exit(1);
}

const BASE_URL   = config.supabase_url;
const SERVICE_KEY = config.supabase_service_key;
const COURSE_ID  = 'phys-215';
const MISS_RATE  = 0.10; // ~10% of students per section don't submit

if (!BASE_URL || !SERVICE_KEY) {
  console.error('config.json must contain supabase_url and supabase_service_key');
  process.exit(1);
}

// ── Supabase REST helpers ─────────────────────────────────────
const HEADERS = {
  'Content-Type':  'application/json',
  'apikey':        SERVICE_KEY,
  'Authorization': `Bearer ${SERVICE_KEY}`,
};

async function dbGet(table, params = '') {
  const url = `${BASE_URL}/rest/v1/${table}?${params}`;
  const resp = await fetch(url, { headers: { ...HEADERS, Accept: 'application/json' } });
  if (!resp.ok) throw new Error(`GET /${table} → ${resp.status}: ${await resp.text()}`);
  return resp.json();
}

async function dbUpsert(table, rows) {
  if (!rows.length) return;
  const url  = `${BASE_URL}/rest/v1/${table}`;
  const resp = await fetch(url, {
    method:  'POST',
    headers: { ...HEADERS, Prefer: 'resolution=merge-duplicates,return=minimal' },
    body:    JSON.stringify(rows),
  });
  if (!resp.ok) throw new Error(`UPSERT /${table} → ${resp.status}: ${await resp.text()}`);
}

// ── Response templates ────────────────────────────────────────
// 10 sections × 2 response styles each for q2/q3.
// Sections are indexed 0–9 in order: M1A M3A M1B M3B M5A T1A T3A T1B T3B T5A

// Preflight-1: electrostatics / charged insulator near metal
const PF1_Q2 = [
  // M1A
  "I found the section on Coulomb's Law most interesting — the idea that two charges can exert forces across empty space without touching is still strange to me. The confusing part was how the permittivity constant ε₀ shows up in the formula and what it physically represents.",
  // M3A
  "Most confusing: why conductors have free electrons at all. I understand that in metals, outer electrons are loosely bound, but I couldn't fully picture what keeps them from just flying off. Most interesting: that you can induce charge without actually touching the object.",
  // M1B
  "The reading on electric field lines was interesting — how they never cross and always point away from positive charges. What confused me was how to add up contributions from multiple charges to get the total field at a point.",
  // M3B
  "Interesting: the idea that a Faraday cage blocks electric fields inside. I didn't know that was why cars are safe during lightning. Confusing: how charge distributes on the surface of an irregular conductor — why does it pile up at sharp points?",
  // M5A
  "Most interesting was learning about static electricity buildup and how grounding removes it. What confused me was the difference between polarization of a dielectric versus actual charge transfer — I kept mixing the two up.",
  // T1A
  "I found Coulomb's law straightforward, but the concept of electric flux through a surface was hard to picture. I'm still not sure I understand what it means for flux to be zero through a closed surface with no enclosed charge.",
  // T3A
  "Interesting: that the electric field inside a conductor in static equilibrium is exactly zero, not just small. Confusing: how charge rearranges so quickly — is it really instantaneous?",
  // T1B
  "The superposition principle for electric fields was interesting — you can just add individual field vectors. What confused me was the difference between a test charge and a source charge and why we need both concepts.",
  // T3B
  "Most confusing: why the electric field lines have to end on charges — I thought they could just extend to infinity. Most interesting: how you can map out the field by placing tiny test charges at different locations.",
  // T5A
  "I found the section on charge induction most interesting, especially how you can permanently charge a neutral object without contact. The confusing part was the difference between induction and polarization — they seem similar.",
];

const PF1_Q3_VARIANTS = [
  // full credit — correct induction explanation (quality A)
  [
    "They attract. The charged insulator creates an electric field that penetrates the metal. Free electrons in the metal redistribute in response — they accumulate on the side nearest the insulator if the insulator is positively charged, leaving a net positive charge on the far side. This separation creates an induced dipole, and the near side (opposite charge) is closer to the insulator than the far side (same charge), so the net force is attractive.",
    "They attract. The metal has free electrons that can move when an external electric field is applied. The charged insulator polarizes the metal by drawing electrons toward it (if it's positive) or pushing them away (if it's negative). The result is a charge distribution on the metal with opposite charge facing the insulator, producing a net attractive force even though the metal has no net charge.",
    "Attraction. When the charged insulator is brought near, it induces a redistribution of free electrons in the conductor. The near face acquires a charge opposite to the insulator's, and the far face an equal same-sign charge. Because the attractive force between the insulator and the near face is stronger (shorter distance) than the repulsive force with the far face (longer distance), the net force is attractive.",
  ],
  // warn — correct conclusion, vague mechanism
  [
    "They attract. The charge on the insulator sort of pulls the charges in the metal toward it, so the side of the metal closer to the insulator becomes oppositely charged. Since unlike charges attract, they pull toward each other.",
    "They attract because the electrons in the metal can move and they rearrange in response to the charged insulator. The metal ends up with a slightly opposite charge on the near side, which pulls the insulator toward it.",
    "I think they attract. The charged insulator induces some charge movement in the metal so the surfaces end up with opposite charges facing each other, which causes attraction.",
  ],
  // zero — says repel, or wrong reasoning
  [
    "They repel. The charged insulator would push the charges in the metal away, creating the same type of charge on the near surface of the metal, leading to repulsion.",
    "The metal object is neutral so it wouldn't feel any force — charged objects only attract or repel other charged objects, and since the metal has zero net charge, nothing happens.",
    "They repel because the insulator is charged and the metal object is a good conductor, so the same charge would build up on the surface and push it away.",
  ],
];

// Preflight-2: polarizers / Malus's law
const PF2_Q2 = [
  // M1A
  "Most interesting: Malus's Law and how intensity drops as cos² of the angle between the polarizers. Confusing: I understand the formula but I'm not sure where the cos² comes from physically — why squared and not just cos?",
  // M3A
  "Interesting: that two crossed polarizers block essentially all light. It's counterintuitive that adding a third polarizer at 45° between them actually lets some light through again. Confusing: the relationship between polarization direction and the electric field vector.",
  // M1B
  "Most confusing: I don't fully understand what 'linearly polarized' means at the level of individual photons. I get the wave picture but not the quantum picture. Interesting: that reflected sunlight is horizontally polarized, which is why polaroid sunglasses reduce glare.",
  // M3B
  "Interesting: birefringent materials have two different refractive indices depending on polarization — that seems bizarre. Confusing: how a quarter-wave plate converts linear to circular polarization.",
  // M5A
  "Most interesting was learning about 3D movie technology — how two polarized images are used to create depth perception. What confused me was the difference between linear and circular polarization and how LCDs exploit both.",
  // T1A
  "I found Brewster's angle interesting — at a specific incidence angle, the reflected light is completely linearly polarized. Confusing: how you calculate Brewster's angle and why the reflected beam becomes polarized at all.",
  // T3A
  "Interesting: the sky is polarized and you can actually see the pattern with polaroid glasses if you know where to look. Confusing: why scattering polarizes the light — I'd like to understand the physical mechanism better.",
  // T1B
  "Most confusing was how optical activity works — some chiral molecules can rotate the plane of polarization. I can follow the description but I have no intuition for why handedness in a molecule affects light.",
  // T3B
  "Interesting: that polarization filters are used in photography to reduce reflections and saturate colors. Confusing: I don't understand the relationship between the angle of the polarizer and the direction of the electric field in the wave.",
  // T5A
  "Most interesting: that LCD displays work by rotating the polarization state of light. I didn't realize every pixel is essentially a controllable polarization rotator. Confusing: the phase retardation explanation — I couldn't follow the math.",
];

const PF2_Q3_VARIANTS = [
  // full credit — Malus's Law, cos²θ, angle explanation (quality A)
  [
    "The two polarizers are oriented at different angles. The first polarizer restricts the light to one plane of vibration — it becomes linearly polarized. The second polarizer only transmits the component of that polarized light aligned with its own transmission axis. By Malus's Law, the transmitted intensity is I = I₀cos²θ, where θ is the angle between the two axes. If θ is large, cos²θ is small and very little light gets through, making the bulb appear dim.",
    "Each polarizer only passes the component of light vibrating in its transmission direction. After the first, the light is linearly polarized. The second polarizer transmits fraction cos²θ of that intensity (Malus's Law), where θ is the angle between the polarizers' axes. A large angle gives a small cos²θ, hence the dim appearance. At 90° the transmitted intensity is zero.",
    "The first polarizer creates linearly polarized light. The second is rotated by angle θ relative to the first. By Malus's Law, the intensity after the second polarizer is I = I₀cos²θ. Since the two polarizers are at a large angle, cos²θ is close to zero and most of the light is blocked. This is why the source looks very dim.",
  ],
  // warn — correct conclusion (blocks light), no formula
  [
    "The two polarizers are set at different angles, so they don't both pass the same direction of light. After going through the first, the light only vibrates in one direction. The second polarizer is at an angle and can only transmit the part that aligns with it, so most of the light gets blocked and the source looks dim.",
    "The polarizers are oriented differently, so only a small fraction of the light that passes through the first one also makes it through the second. The more they are rotated relative to each other, the less light gets through and the dimmer the source appears.",
    "The two polarizers filter light differently because they're at different angles. The first one restricts the light to one polarization direction, and the second one is misaligned so it blocks most of that light, making the source look dim.",
  ],
  // zero — vague/wrong physics
  [
    "The polarizers absorb most of the light, so less reaches your eye. Two in a row means more absorption than one.",
    "The light has to pass through two filters, which reduces the intensity significantly. Each filter blocks part of the light spectrum.",
    "",
  ],
];

// Reading time pools
const READING_TIMES = [
  "15 minutes.", "About 20 minutes.", "30 minutes.", "About 30 minutes.",
  "35 minutes.", "40 minutes.", "About 45 minutes.", "50 minutes.",
  "1 hour.", "About an hour.", "1 hour and 15 minutes.", "2 hours.",
  "I skimmed it, maybe 20 minutes.", "Close to an hour.", "Zero, I didn't have time.",
  "Around 25 minutes.", "Nearly an hour.", "About 55 minutes.", "Half an hour.",
  "I spent about an hour reading.", "Roughly 45 minutes.",
];

// Section order (matches the 10 Q2/Q3 arrays above by index)
const SECTION_ORDER = ['M1A', 'M3A', 'M1B', 'M3B', 'M5A', 'T1A', 'T3A', 'T1B', 'T3B', 'T5A'];

function getSectionIdx(sectionId) {
  const idx = SECTION_ORDER.indexOf(sectionId);
  return idx >= 0 ? idx : 0;
}

// Deterministic variant selection based on student_id to ensure variety within sections
function pick(arr, seed) {
  return arr[seed % arr.length];
}

// What quality tier does a student get? Roughly 65% full, 20% warn, 15% zero
function getQualityTier(studentId, assignmentIdx) {
  const v = (studentId * 31 + assignmentIdx * 7) % 100;
  if (v < 65) return 'full';
  if (v < 85) return 'warn';
  return 'zero';
}

function generateAnswers(assignmentId, sectionId, student) {
  const sIdx  = getSectionIdx(sectionId);
  const sid   = student.student_id;
  const aIdx  = assignmentId === 'preflight-1' ? 0 : 1;

  const q1  = pick(READING_TIMES, sid + aIdx);
  const q2  = assignmentId === 'preflight-1' ? PF1_Q2[sIdx] : PF2_Q2[sIdx];
  const tier = getQualityTier(sid, aIdx);

  const q3variants = assignmentId === 'preflight-1'
    ? PF1_Q3_VARIANTS[tier === 'full' ? 0 : tier === 'warn' ? 1 : 2]
    : PF2_Q3_VARIANTS[tier === 'full' ? 0 : tier === 'warn' ? 1 : 2];
  const q3 = pick(q3variants, sid);

  return { q1, q2, q3 };
}

function generateScore(assignmentId, answers, studentId, sectionId) {
  const aIdx = assignmentId === 'preflight-1' ? 0 : 1;
  const tier = getQualityTier(studentId, aIdx);

  // q1: always full if any answer
  const q1Score = answers.q1 ? { score: 0.1, max: 0.1, feedback: '', status: 'full' }
                              : { score: 0,   max: 0.1, feedback: 'No answer provided.', status: 'zero' };

  // q2: full if >60 chars, warn if 10-60, zero if blank
  const q2len   = (answers.q2 || '').length;
  const q2Score = q2len > 60  ? { score: 0.9, max: 0.9, feedback: '', status: 'full' }
                : q2len >= 10 ? { score: 0.9, max: 0.9,
                                  feedback: "While we gave you credit, please try to be more thorough in future preflights.",
                                  status: 'warn' }
                               : { score: 0,   max: 0.9, feedback: 'No substantive answer provided.', status: 'zero' };

  // q3: based on quality tier
  const pf1Feedback = {
    full: '',
    warn: 'Full credit, but try to be more specific — mention free electron redistribution and induced dipole.',
    zero: answers.q3
      ? 'Incorrect. They attract due to electrostatic induction: free electrons in the conductor redistribute, creating an induced dipole with opposite charge facing the insulator.'
      : 'No answer provided.',
  };
  const pf2Feedback = {
    full: '',
    warn: "Full credit. For full marks on future preflights, try to include Malus's Law (I = I₀cos²θ) and explain the role of the angle.",
    zero: answers.q3
      ? "Incorrect. The dimness comes from Malus's Law: after the first polarizer, light is linearly polarized. The second transmits only the cos²θ fraction, where θ is the angle between the axes. A large angle → small cos²θ → dim source."
      : 'No answer provided.',
  };
  const fbMap = assignmentId === 'preflight-1' ? pf1Feedback : pf2Feedback;
  const q3Score = tier === 'full' ? { score: 1.0, max: 1.0, feedback: fbMap.full, status: 'full' }
                : tier === 'warn' ? { score: 1.0, max: 1.0, feedback: fbMap.warn, status: 'warn' }
                                  : { score: 0,   max: 1.0, feedback: fbMap.zero, status: 'zero' };

  const totalScore = q1Score.score + q2Score.score + q3Score.score;
  const maxTotal   = 2.0;

  return {
    student_id:      studentId,
    assignment_id:   assignmentId,
    question_scores: { q1: q1Score, q2: q2Score, q3: q3Score },
    total_score:     Math.round(totalScore * 100) / 100,
    max_total:       maxTotal,
    is_finalized:    false,
  };
}

function randomSubmitDate(assignmentId) {
  // Random datetime within 48 hours before "now" (simulating recent submissions)
  const base   = new Date('2026-06-04T20:00:00Z').getTime();
  const spread = 48 * 60 * 60 * 1000;
  const ts     = base - Math.random() * spread;
  return new Date(ts).toISOString();
}

// ── Main ──────────────────────────────────────────────────────
async function main() {
  console.log('Fetching phys-215 sections…');
  const sections = await dbGet('sections', `course_id=eq.${COURSE_ID}&select=id`);
  const sectionIds = sections.map(s => s.id);

  if (!sectionIds.length) {
    console.error('No sections found for phys-215. Upload the roster CSV first.');
    process.exit(1);
  }
  console.log(`Found ${sectionIds.length} section(s): ${sectionIds.join(', ')}`);

  console.log('Fetching students…');
  const students = await dbGet(
    'students',
    `section_id=in.(${sectionIds.join(',')})&select=student_id,name,section_id&order=section_id,student_id`
  );
  console.log(`Found ${students.length} students`);

  if (!students.length) {
    console.error('No students found. Upload the roster CSV first.');
    process.exit(1);
  }

  // Group by section
  const bySect = {};
  for (const s of students) {
    (bySect[s.section_id] = bySect[s.section_id] || []).push(s);
  }

  const assignments = ['preflight-1', 'preflight-2'];

  for (const assignmentId of assignments) {
    console.log(`\nGenerating responses for ${assignmentId}…`);
    const responses = [];
    const scores    = [];

    for (const [sectionId, sectStudents] of Object.entries(bySect)) {
      // Select ~10% to be "missing" — deterministically based on student_id
      const skipCount = Math.round(sectStudents.length * MISS_RATE);
      const sorted    = [...sectStudents].sort((a, b) => a.student_id - b.student_id);
      // Skip the students whose ID mod 10 === 0 (roughly 10%)
      const skipSet   = new Set(sorted.filter(s => s.student_id % 10 === 0).slice(0, skipCount).map(s => s.student_id));

      for (const student of sectStudents) {
        if (skipSet.has(student.student_id)) continue;
        const answers = generateAnswers(assignmentId, sectionId, student);
        const dt      = randomSubmitDate(assignmentId);
        responses.push({
          student_id:    student.student_id,
          assignment_id: assignmentId,
          answers,
          submitted_at:  dt,
          updated_at:    dt,
        });
        scores.push(generateScore(assignmentId, answers, student.student_id, sectionId));
      }
    }

    const submitting = responses.length;
    const missing    = students.length - submitting;
    console.log(`  ${submitting} submissions, ${missing} missing`);

    // Upsert in chunks
    const CHUNK = 500;
    console.log(`  Upserting responses…`);
    for (let i = 0; i < responses.length; i += CHUNK) {
      await dbUpsert('responses', responses.slice(i, i + CHUNK));
      process.stdout.write(`    ${Math.min(i + CHUNK, responses.length)}/${responses.length}\r`);
    }
    console.log(`  ✓ ${responses.length} responses upserted`);

    console.log(`  Upserting scores (unfinalized)…`);
    for (let i = 0; i < scores.length; i += CHUNK) {
      await dbUpsert('scores', scores.slice(i, i + CHUNK));
      process.stdout.write(`    ${Math.min(i + CHUNK, scores.length)}/${scores.length}\r`);
    }
    console.log(`  ✓ ${scores.length} scores upserted`);
  }

  console.log('\n✓ Done! Open admin.html → Grade tab to review suggested scores.');
  console.log('  Verify student login: ID 3000100001, password 100001');
}

main().catch(err => {
  console.error('Fatal error:', err.message);
  process.exit(1);
});
