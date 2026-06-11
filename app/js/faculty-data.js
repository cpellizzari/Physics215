// faculty-data.js — per-section roll-up for the faculty dashboard, scoped to the
// instructor's current course. Uses only existing tables. Section scoping mirrors the
// legacy admin.html (client-side): directors/admins see all sections in the course,
// instructors see only the sections they teach. (RLS is permissive — see plan notes.)

import { db } from './supabase.js';

const CHUNK = 300; // keep .in() URLs under GET length limits for large courses

/** Run a select filtered by assignment_id IN asgnIds AND student_id IN (chunked) ids. */
async function factsByAssignmentAndStudent(table, columns, asgnIds, studentIds) {
  if (!asgnIds.length || !studentIds.length) return [];
  const out = [];
  for (let i = 0; i < studentIds.length; i += CHUNK) {
    const { data } = await db.from(table).select(columns)
      .in('assignment_id', asgnIds).in('student_id', studentIds.slice(i, i + CHUNK));
    if (data) out.push(...data);
  }
  return out;
}

async function reportsByStudent(studentIds) {
  if (!studentIds.length) return [];
  const out = [];
  for (let i = 0; i < studentIds.length; i += CHUNK) {
    const { data } = await db.from('preflight_interaction_reports')
      .select('student_id, interaction_id').in('student_id', studentIds.slice(i, i + CHUNK));
    if (data) out.push(...data);
  }
  return out;
}

export async function loadFacultyDashboard(ctx) {
  const course = ctx.currentCourse;
  if (!course) return { noCourse: true };

  const isDirector = ctx.isDirectorForCurrent();

  // 1) Covered sections
  let secQuery = db.from('sections').select('id, instructor_id').eq('course_id', course).order('id');
  if (!isDirector) secQuery = secQuery.eq('instructor_id', ctx.instructorRow.id);
  const { data: sectionRows } = await secQuery;
  const sections = sectionRows || [];
  if (!sections.length) return { noCourse: false, isDirector, noSections: true };

  const sectionIds = sections.map(s => s.id);

  // 2) Roster + recent assignments + published interactions (parallel)
  const [{ data: studentsRaw }, { data: asgnsRaw }, { data: interRaw }] = await Promise.all([
    db.from('students').select('student_id, name, section_id').in('section_id', sectionIds),
    db.from('assignments').select('id, title, due_date_m, due_date_t')
      .eq('course_id', course).eq('is_published', true)
      .order('due_date_m', { ascending: false, nullsFirst: false }).limit(5),
    db.from('interactions').select('id, title').eq('course_id', course).eq('is_published', true),
  ]);

  const students = studentsRaw || [];
  const assignments = (asgnsRaw || []).slice().reverse(); // show oldest→newest in cards
  const interactions = interRaw || [];
  const studentIds = students.map(s => s.student_id);
  const sectionOf = Object.fromEntries(students.map(s => [s.student_id, s.section_id]));
  const asgnIds = assignments.map(a => a.id);

  // Instructor names for section labels (directors view shows who teaches each section)
  let instrName = {};
  const instrIds = [...new Set(sections.map(s => s.instructor_id).filter(Boolean))];
  if (instrIds.length) {
    const { data: instrs } = await db.from('instructors').select('id, name').in('id', instrIds);
    instrName = Object.fromEntries((instrs || []).map(i => [i.id, i.name]));
  }

  // 3) Submission + grading facts + interaction reports
  const [responses, scores, reports] = await Promise.all([
    factsByAssignmentAndStudent('responses', 'student_id, assignment_id', asgnIds, studentIds),
    factsByAssignmentAndStudent('scores', 'student_id, assignment_id, is_finalized', asgnIds, studentIds),
    reportsByStudent(studentIds),
  ]);

  // Index facts: assignmentId -> Set(studentId)
  const submittedBy = {}, gradedBy = {};
  asgnIds.forEach(id => { submittedBy[id] = new Set(); gradedBy[id] = new Set(); });
  responses.forEach(r => submittedBy[r.assignment_id]?.add(r.student_id));
  scores.forEach(s => { if (s.is_finalized) gradedBy[s.assignment_id]?.add(s.student_id); });

  const interIds = new Set(interactions.map(i => i.id));
  const reportsOf = {}; // studentId -> Set(interactionId) limited to published interactions
  reports.forEach(r => {
    if (!interIds.has(r.interaction_id)) return;
    (reportsOf[r.student_id] ||= new Set()).add(r.interaction_id);
  });

  // 4) Per-section aggregation (pure JS, no extra queries)
  const studentsBySection = {};
  sectionIds.forEach(id => studentsBySection[id] = []);
  students.forEach(s => studentsBySection[s.section_id]?.push(s.student_id));

  let totSubmitted = 0, totPossible = 0, totGraded = 0, totNeedsGrading = 0;
  let totInterDone = 0, totInterPossible = 0;

  const sectionCards = sections.map(sec => {
    const roster = studentsBySection[sec.id] || [];
    const n = roster.length;

    const perAssignment = assignments.map(a => {
      const submitted = roster.filter(id => submittedBy[a.id]?.has(id)).length;
      const graded = roster.filter(id => gradedBy[a.id]?.has(id)).length;
      totSubmitted += submitted; totPossible += n; totGraded += graded;
      totNeedsGrading += Math.max(0, submitted - graded);
      return { id: a.id, title: a.title, submitted, graded, total: n };
    });

    // interaction completion = reports across roster / (n × published count)
    let interDone = 0;
    roster.forEach(id => { interDone += [...(reportsOf[id] || [])].filter(x => interIds.has(x)).length; });
    const interPossible = n * interactions.length;
    totInterDone += interDone; totInterPossible += interPossible;

    return {
      id: sec.id,
      instructorName: instrName[sec.instructor_id] || null,
      studentCount: n,
      perAssignment,
      interaction: { done: interDone, total: interPossible },
    };
  });

  return {
    noCourse: false, noSections: false, isDirector,
    courseTitle: ctx.courseTitleOf(course),
    totals: {
      sections: sections.length,
      students: students.length,
      assignmentsTracked: assignments.length,
      needsGrading: totNeedsGrading,
      submittedPct: totPossible ? Math.round((totSubmitted / totPossible) * 100) : 0,
      gradedPct: totPossible ? Math.round((totGraded / totPossible) * 100) : 0,
      interactionsPct: totInterPossible ? Math.round((totInterDone / totInterPossible) * 100) : 0,
    },
    assignments, interactions, sections: sectionCards,
  };
}

/**
 * Interaction-completion roll-up for the faculty interactions page: per published
 * interaction, completion broken down by covered section, plus section rosters (with
 * student names) for the per-student report viewer.
 */
export async function loadFacultyInteractions(ctx) {
  const course = ctx.currentCourse;
  if (!course) return { noCourse: true };
  const isDirector = ctx.isDirectorForCurrent();

  let secQuery = db.from('sections').select('id, instructor_id').eq('course_id', course).order('id');
  if (!isDirector) secQuery = secQuery.eq('instructor_id', ctx.instructorRow.id);
  const { data: sectionRows } = await secQuery;
  const sections = sectionRows || [];
  if (!sections.length) return { noCourse: false, noSections: true };
  const sectionIds = sections.map(s => s.id);

  const [{ data: studentsRaw }, { data: interRaw }] = await Promise.all([
    db.from('students').select('student_id, name, section_id').in('section_id', sectionIds).order('name'),
    db.from('interactions').select('id, title, description').eq('course_id', course).eq('is_published', true).order('title'),
  ]);
  const students = studentsRaw || [];
  const interactions = interRaw || [];
  const studentIds = students.map(s => s.student_id);
  const sectionOf = Object.fromEntries(students.map(s => [s.student_id, s.section_id]));

  const reports = await reportsByStudent(studentIds);
  const interIds = new Set(interactions.map(i => i.id));
  // (interactionId, sectionId) -> count done
  const doneKey = {};
  reports.forEach(r => {
    if (!interIds.has(r.interaction_id)) return;
    const sec = sectionOf[r.student_id]; if (!sec) return;
    doneKey[`${r.interaction_id}|${sec}`] = (doneKey[`${r.interaction_id}|${sec}`] || 0) + 1;
  });

  const sectionSize = {};
  sectionIds.forEach(id => sectionSize[id] = 0);
  students.forEach(s => { if (sectionSize[s.section_id] != null) sectionSize[s.section_id]++; });

  const interactionCards = interactions.map(it => {
    let done = 0, total = 0;
    const perSection = sections.map(sec => {
      const d = doneKey[`${it.id}|${sec.id}`] || 0;
      const n = sectionSize[sec.id] || 0;
      done += d; total += n;
      return { sectionId: sec.id, done: d, total: n };
    });
    return { ...it, perSection, done, total };
  });

  const sectionRosters = sections.map(sec => ({
    id: sec.id,
    students: students.filter(s => s.section_id === sec.id).map(s => ({ student_id: s.student_id, name: s.name })),
  }));

  return { noCourse: false, noSections: false, courseTitle: ctx.courseTitleOf(course),
    interactions: interactionCards, sections: sectionRosters };
}
