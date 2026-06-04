# Core Preflights — Instructor Guide

**Live site**: https://dfpm-physics.github.io/Core_Preflights/
**Admin panel**: https://dfpm-physics.github.io/Core_Preflights/admin.html
**Supabase dashboard**: https://supabase.com/dashboard/project/shzvpmlnqfmzfmuxkowi
**GitHub repo**: https://github.com/dfpm-physics/Core_Preflights

---

## Roles

| Role | Can do |
|---|---|
| **Course Director** | Everything — create assignments, upload rosters, manage sections, run Claude analysis, export grades |
| **Instructor** | Grade their own sections, view submission reports, export their sections |

The course director account is `casey.pellizzari@afacademy.af.edu`. Director-only tabs (Assignments, Roster, Sections) are hidden from regular instructor accounts.

---

## Adding an Instructor

Instructors need two things: a login account and section assignments.

**Step 1 — Create their login (Supabase dashboard)**

1. Go to the [Supabase Auth dashboard](https://supabase.com/dashboard/project/shzvpmlnqfmzfmuxkowi/auth/users)
2. Click **Add user → Create new user**
3. Enter their USAFA email and a temporary password (e.g., their last name + `215`)
4. Open the **SQL Editor** and run:

```sql
-- Replace values with actual name, email, and course
INSERT INTO instructors (id, name, is_global_admin)
SELECT id, 'First Last', false
FROM auth.users WHERE email = 'instructor@afacademy.af.edu';

INSERT INTO instructor_course_access (instructor_id, course_id, role)
SELECT id, 'phys-215', 'instructor'
FROM auth.users WHERE email = 'instructor@afacademy.af.edu';
```

5. Send them the URL and temporary password. They can change their password after first login.

**Step 2 — Assign their sections**

1. Log into the admin panel as course director
2. Go to the **Sections** tab
3. Use the dropdown next to each section ID to assign the instructor

---

## Removing an Instructor

1. In the **Sections** tab, reassign their sections to another instructor
2. In the [Supabase Auth dashboard](https://supabase.com/dashboard/project/shzvpmlnqfmzfmuxkowi/auth/users), find the user and click **Delete user**

---

## Adding Students (Roster Upload)

Students are uploaded via CSV at the start of each semester.

**CSV format** (no header row needed, but including one is fine):
```
student_id,name,section
3000123456,Smith John,M1A
3000234567,Jones Jane,T3B
```

- `student_id`: 10-digit number starting with `3000`
- `section`: must match an existing section ID (e.g., `M1A`, `T3C`)

**To upload:**
1. Log into the admin panel
2. Select the correct course (Physics 215 or Physics 110) using the pills at the top
3. Go to the **Roster** tab
4. Click **Choose File**, select your CSV, then click **Upload Roster**

The page will preview the data and report any invalid student IDs or unknown section codes before committing.

---

## Removing a Student

There is no UI for removing individual students. Use the Supabase SQL editor:

```sql
-- Removes the student and all their responses/scores
DELETE FROM scores WHERE student_id = 3000123456;
DELETE FROM responses WHERE student_id = 3000123456;
DELETE FROM students WHERE student_id = 3000123456;
```

---

## Running the Claude Analysis Skill (`/preflight-analyze`)

The skill reads student submissions, checks them for physics misconceptions, writes suggested scores to Supabase, and prints a per-section report. Instructors run it locally on their own computer.

### One-time setup

**1. Install Claude Code**

Download and install from https://claude.ai/code (available for Mac and Windows).
You will need an Anthropic account — sign up at https://anthropic.com if you don't have one.

**2. Clone the repo**

```bash
git clone https://github.com/dfpm-physics/Core_Preflights.git
cd Core_Preflights
```

**3. Create your config file**

```bash
cp .claude/skills/preflight-analyze/config.json.template \
   .claude/skills/preflight-analyze/config.json
```

Open `config.json` and fill in the values:

```json
{
  "supabase_url": "https://shzvpmlnqfmzfmuxkowi.supabase.co",
  "supabase_service_key": "GET THIS FROM THE COURSE DIRECTOR",
  "textbook_base_path": "/path/to/your/local/textbooks/",
  "default_course_id": "phys-215"
}
```

- `supabase_service_key`: a secret key that bypasses Supabase security — get it from the course director, never share it or commit it to GitHub
- `textbook_base_path`: the folder on your computer where the textbook PDFs live (the OpenStax University Physics volumes)

**The `config.json` file is gitignored and will never be committed to the repo.**

### Running the skill

Open Claude Code in your terminal from the repo folder and type:

```
/preflight-analyze phys-215 preflight-2
```

Optional filters:
```
/preflight-analyze phys-215 preflight-2 M    ← M-day sections only
/preflight-analyze phys-215 preflight-2 T    ← T-day sections only
```

The skill will:
1. Fetch all student responses for the assignment
2. Read the relevant textbook pages (if configured on the assignment)
3. Grade numerical and multiple choice questions automatically
4. Analyze free-response answers for misconceptions
5. Write suggested scores to Supabase (`is_finalized = false`)
6. Print a full per-instructor report in the terminal

Suggested scores appear highlighted in the admin **Grade** tab. Instructors review them and click **Finalize** to publish grades to students.

---

## Starting a New Semester

Use the same assignments with updated due dates. The process clears all student data and submissions while keeping assignments intact.

**Step 1 — Clear last semester's data (Supabase SQL editor)**

```sql
-- Clear in this order to respect foreign key constraints
TRUNCATE TABLE scores;
TRUNCATE TABLE responses;
DELETE FROM students;
```

**Step 2 — Upload the new roster**

Follow the Roster Upload steps above with the new semester's CSV.

**Step 3 — Reassign instructor sections**

Go to the **Sections** tab in the admin panel and update the instructor assignment for each section. Section IDs (e.g., `M1A`, `T3B`) stay the same across semesters — just change who is assigned to each one.

**Step 4 — Update assignment due dates**

Go to the **Assignments** tab and update the M-day and T-day due dates for each assignment. Assignments stay published — students will see them as soon as the due dates are current.

**Step 5 — Verify**

Open the student page at https://dfpm-physics.github.io/Core_Preflights/ and enter a test student ID to confirm the assignment list looks correct.

---

## Exporting Grades to Blackboard

1. Log into the admin panel as course director
2. Go to the **Export** tab
3. Click **Download Blackboard CSV**

The file (`CorePreflights_Grades_YYYY-MM-DD.csv`) contains one row per student and one column per finalized assignment. Import it directly into Blackboard.

Only finalized assignments are included as columns. Unfinalized assignments are omitted.

---

## Course Director Service Key

The Supabase service role key is required for the Claude skill and bypasses all database security. It is stored at:

```
~/.claude/skills/preflight-analyze/config.json
```

To find it: Supabase dashboard → **Project Settings → API → service_role key** (click to reveal).

**Never commit this key to GitHub.** Share it with instructors only via a secure channel (e.g., a password manager or encrypted message).
