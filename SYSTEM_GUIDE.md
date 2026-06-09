# Core Preflights — System Guide

**Live site**: https://dfpm-physics.github.io/Core_Preflights/
**Admin panel**: https://dfpm-physics.github.io/Core_Preflights/admin.html
**Supabase dashboard**: https://supabase.com/dashboard/project/shzvpmlnqfmzfmuxkowi
**GitHub repo**: https://github.com/dfpm-physics/Core_Preflights

---

## Roles

There are three roles, each with increasing access:

| Role | Access | Use for |
|---|---|---|
| **Instructor** | Grade their own sections, view reports, export, grant student extensions | Regular instructors |
| **Course Director** | Full access to one course — create assignments, upload roster, manage sections and instructors | Section leaders per course |
| **System Admin** | Full access to all courses (Physics 110 and Physics 215) | Department directors, system maintainers |

Director-only tabs (Assignments, Roster, Sections, Instructors) are hidden from regular Instructor accounts. System Admins see all tabs for all courses.

Only a System Admin can create another System Admin.

---

## Adding an Instructor

Everything is done from the admin panel — no SQL required.

1. Log into the admin panel as a Course Director or System Admin
2. Go to the **Instructors** tab
3. Fill in the instructor's name, USAFA email, and a temporary password
4. Select their role and click **Add Instructor**:
   - **Instructor** — grades their own sections only
   - **Course Director** — full access to the currently selected course
   - **System Admin** — full access to all courses (Physics 110 + 215); only an existing System Admin can create another one
5. Send them the admin panel URL and their temporary password — they change it themselves after first login (see [Changing Your Password](#changing-your-password) below)
6. Go to the **Sections** tab and assign them to their sections (not needed for System Admins)

> **Note:** The temporary password can be anything — the instructor changes it themselves after logging in.

---

## Removing an Instructor

1. In the **Sections** tab, reassign their sections to another instructor
2. Go to the **Instructors** tab and click **Remove** next to their name

For regular instructors and directors, this removes their course access for the currently selected course. For System Admins, it clears their global admin flag.

Their login account remains in the system but loses all access — if you need to permanently delete it, go to the [Supabase Auth dashboard](https://supabase.com/dashboard/project/shzvpmlnqfmzfmuxkowi/auth/users) and delete the user there.

> **Note:** Only a System Admin can remove another System Admin.

---

## Changing Your Password

Any logged-in instructor can change their own password without contacting the course director.

1. Log into the admin panel
2. Click **Change Password** in the top-right corner of the header
3. Enter a new password (at least 6 characters) and confirm it
4. Click **Save Password** — the modal closes automatically on success

> This is how new instructors should change their temporary password on first login.

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

## Editing or Removing a Student

Both actions are available directly in the **Roster** tab — no SQL required.

**To change a student's section:**
1. Go to the **Roster** tab
2. Find the student and click **Edit Section**
3. Select the new section from the dropdown and click **Save**

**To remove a student:**
1. Go to the **Roster** tab
2. Find the student and click **Remove**
3. Confirm the prompt — this permanently deletes their record, all submissions, and all scores

---

## Granting a Student Extension

Any instructor can grant an extension from the Grade tab.

1. Go to the **Grade** tab and select the assignment
2. Find the student's card and click **📅 Grant Extension**
3. Pick the new due date and time, then click **Save Extension**

The student's assignment page will automatically use the extended date. The extension badge shows on their card so instructors can see it at a glance. Extensions can be edited or removed at any time before the student submits.

---

## Running the Claude Analysis Skill (`/preflight-analyze`)

The skill reads student submissions, checks them for physics misconceptions, writes suggested scores to Supabase, and prints a per-instructor report. **Only Course Directors and System Admins run this skill** — not individual instructors. A CD runs it once for all M-day sections and once for all T-day sections. Each instructor then sees their own section's results in the Report tab.

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

### Running the skill (Course Director / System Admin only)

Open Claude Code in your terminal from the repo folder and run it twice — once per day group:

```
/preflight-analyze phys-215 preflight-2 M    ← all M-day sections
/preflight-analyze phys-215 preflight-2 T    ← all T-day sections
```

Each run:
1. Fetches all student responses for that day's sections
2. Reads the relevant textbook pages (if configured on the assignment)
3. Grades numerical and multiple choice questions automatically
4. Analyzes free-response answers for physics misconceptions
5. Writes suggested scores to Supabase (`is_finalized = false`) for every student
6. Prints a per-instructor breakdown in the terminal

Results are stored by instructor in the database. After the skill runs, each instructor logs into the admin panel, goes to the **Grade** tab, and reviews the suggested scores for their own sections. They click **Finalize & Publish** to make grades visible to students.

**Grading policy**: wrong answers that show genuine engagement with the topic are marked yellow (full credit, flagged for review) — not zero. Only blank or completely off-topic responses receive zero credit. Instructors should review all yellow items and decide whether to confirm full credit, downgrade to no credit, or adjust feedback.

---

## Adding Figures to Assignments

Assignments support two levels of optional figures — an assignment-level figure shown above all questions, and per-question figures shown inline with a specific question.

### Where to put image files

Drop image files into the `img/assignments/` folder in the repo:

```
Core_Preflights/
  img/
    assignments/
      coulombs-law-diagram.png
      force-diagram-q2.png
      ...
```

GitHub Pages serves this folder automatically, so the public URL for any file is:

```
https://dfpm-physics.github.io/Core_Preflights/img/assignments/your-filename.png
```

Commit and push the image file, then use that URL in the admin panel. The image will be live as soon as GitHub Pages deploys (usually under 2 minutes).

You can also use any external image URL (e.g., a link directly from OpenStax or any publicly accessible host) — just paste the full URL.

### How to add a figure

**Assignment-level figure** (shown above all questions):
1. Go to the **Assignments** tab and open or create an assignment
2. Paste the image URL into the **Assignment Figure** field
3. A live preview appears immediately — verify it looks right before saving

**Per-question figure** (shown below a specific question's text):
1. In the question builder, each question has its own **Question Figure** field
2. Paste the URL there — a preview appears inline in the editor

### What students and instructors see

| Context | Assignment figure | Question figure |
|---|---|---|
| Student submission page | Above all questions | Below the question text, above the answer input |
| Student review (graded) | Above all questions | Below the question text |
| Instructor Grade tab | — | Below the question text in each student's card |

Figures are stored as URLs in the database — no file upload to Supabase is needed.

---

## Starting a New Semester

Use the same assignments with updated due dates. The process clears all student data and submissions while keeping assignments intact.

**Step 1 — Clear last semester's data**

Run the following in the [Supabase SQL editor](https://supabase.com/dashboard/project/shzvpmlnqfmzfmuxkowi/sql):

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

**Step 4 — Add or remove instructors as needed**

Use the **Instructors** tab to add new instructors or remove those no longer teaching the course.

**Step 5 — Update assignment due dates**

Go to the **Assignments** tab and update the M-day and T-day due dates for each assignment. Assignments stay published — students will see them as soon as the due dates are current.

**Step 6 — Verify**

Open the student page at https://dfpm-physics.github.io/Core_Preflights/ and enter a test student ID to confirm the assignment list looks correct.

---

## Exporting Grades to Blackboard

1. Log into the admin panel as course director
2. Go to the **Export** tab
3. Click **Download Blackboard CSV**

The file (`CorePreflights_Grades_YYYY-MM-DD.csv`) contains one row per student and one column per finalized assignment. Import it directly into Blackboard.

Only finalized assignments are included as columns. Unfinalized assignments are omitted.

---

## One-Time System Setup (Course Director Only)

This section documents what was done to deploy the system — only needed if starting from scratch or re-deploying.

### Deploy the Edge Functions

Two edge functions handle instructor account creation and removal securely. They only need to be deployed once (or after any code change to them).

**1. Install the Supabase CLI**

```bash
brew install supabase/tap/supabase   # Mac
```
Or download from https://supabase.com/docs/guides/cli

**2. Log in and link the project**

```bash
supabase login
supabase link --project-ref shzvpmlnqfmzfmuxkowi
```

**3. Deploy both functions**

```bash
supabase functions deploy create-instructor
supabase functions deploy remove-instructor
```

That's it — the functions run on Supabase's servers from that point on. No one else needs the CLI.

### Run the RLS Migrations

Run each of these once in the [Supabase SQL editor](https://supabase.com/dashboard/project/shzvpmlnqfmzfmuxkowi/sql). The files also live in `supabase/migrations/` in the repo.

**Instructors read policy** — allows the Instructors tab to list all instructor names:

```sql
-- supabase/migrations/instructors_read_policy.sql
ALTER TABLE instructors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "instructors_read_all" ON instructors;
CREATE POLICY "instructors_read_all" ON instructors
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "instructors_update_own" ON instructors
  FOR UPDATE TO authenticated USING (id = auth.uid());
```

**Student write policy** — allows directors to edit sections and remove students from the Roster tab:

```sql
-- supabase/migrations/students_director_write_policy.sql
CREATE POLICY "directors_update_students" ON students
  FOR UPDATE TO authenticated
  USING (true) WITH CHECK (true);

CREATE POLICY "directors_delete_students" ON students
  FOR DELETE TO authenticated
  USING (true);
```

**Course access read policy** — allows the Instructors tab to list all directors and instructors for a course:

```sql
-- supabase/migrations/instructor_course_access_read_policy.sql
ALTER TABLE instructor_course_access ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "course_access_read_authenticated" ON instructor_course_access;
CREATE POLICY "course_access_read_authenticated" ON instructor_course_access
  FOR SELECT TO authenticated
  USING (true);
```

---

## Course Director Service Key

The Supabase service role key is required for the Claude skill and bypasses all database security. It is stored at:

```
~/.claude/skills/preflight-analyze/config.json
```

To find it: Supabase dashboard → **Project Settings → API → service_role key** (click to reveal).

**Never commit this key to GitHub.** Share it with instructors only via a secure channel (e.g., a password manager or encrypted message).
