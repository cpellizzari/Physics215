# Core Preflights — System Guide

**Live site**: https://dfpm-physics.github.io/Core_Preflights/
**Admin panel**: https://dfpm-physics.github.io/Core_Preflights/admin.html
**Supabase dashboard**: https://supabase.com/dashboard/project/shzvpmlnqfmzfmuxkowi
**GitHub repo**: https://github.com/dfpm-physics/Core_Preflights

---

## Roles

| Role | Can do |
|---|---|
| **Course Director** | Everything — create assignments, upload rosters, manage sections and instructors, run Claude analysis, export grades |
| **Instructor** | Grade their own sections, view submission reports, export their sections, grant student extensions |

The course director account is `casey.pellizzari@afacademy.af.edu`. Director-only tabs (Assignments, Roster, Sections, Instructors) are hidden from regular instructor accounts.

---

## Adding an Instructor

Everything is done from the admin panel — no SQL required.

1. Log into the admin panel as course director
2. Go to the **Instructors** tab
3. Fill in the instructor's name, USAFA email, and a temporary password
4. Select their role (**Instructor** or **Director**) and click **Add Instructor**
5. Send them the admin panel URL and their temporary password — they can change it after first login
6. Go to the **Sections** tab and assign them to their sections

> **Note:** The temporary password can be anything — the instructor changes it themselves after logging in for the first time.

---

## Removing an Instructor

1. In the **Sections** tab, reassign their sections to another instructor
2. Go to the **Instructors** tab and click **Remove** next to their name

This removes their course access. Their login account is deactivated but not fully deleted — if you need to permanently delete it, go to the [Supabase Auth dashboard](https://supabase.com/dashboard/project/shzvpmlnqfmzfmuxkowi/auth/users) and delete the user there.

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

There is no UI for removing individual students. Use the [Supabase SQL editor](https://supabase.com/dashboard/project/shzvpmlnqfmzfmuxkowi/sql):

```sql
-- Removes the student and all their responses/scores
DELETE FROM scores WHERE student_id = 3000123456;
DELETE FROM responses WHERE student_id = 3000123456;
DELETE FROM students WHERE student_id = 3000123456;
```

---

## Granting a Student Extension

Any instructor can grant an extension from the Grade tab.

1. Go to the **Grade** tab and select the assignment
2. Find the student's card and click **📅 Grant Extension**
3. Pick the new due date and time, then click **Save Extension**

The student's assignment page will automatically use the extended date. The extension badge shows on their card so instructors can see it at a glance. Extensions can be edited or removed at any time before the student submits.

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

### Deploy the `create-instructor` Edge Function

The edge function handles instructor account creation securely. It only needs to be deployed once (or after any code change to it).

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

**3. Deploy the function**

```bash
supabase functions deploy create-instructor
```

That's it — the function runs on Supabase's servers from that point on. No one else needs the CLI.

---

## Course Director Service Key

The Supabase service role key is required for the Claude skill and bypasses all database security. It is stored at:

```
~/.claude/skills/preflight-analyze/config.json
```

To find it: Supabase dashboard → **Project Settings → API → service_role key** (click to reveal).

**Never commit this key to GitHub.** Share it with instructors only via a secure channel (e.g., a password manager or encrypted message).
