---
name: setup-preflight
description: >
  One-time setup wizard for the preflight-analyze skill. Run when a new instructor,
  admin, or course director needs to configure their local machine to use the
  preflight analysis and grading tools. Triggers on /setup-preflight, "set up the
  skill", "configure the skill", "first time setup", "how do I get started grading",
  "set up preflight analyze", "onboard to the skill".
---

# Preflight Skill Setup Wizard

You are helping a new Physics 110/215 instructor configure their local machine to run
the `/preflight-analyze` skill. Walk through each step in order, waiting for the user's
input before proceeding. Be conversational and clear — the person may not be technical.

---

## Step 1 — Check for an Existing Config

Run this command to check whether a config file already exists:

```bash
ls ~/.claude/skills/preflight-analyze/config.json 2>/dev/null && echo "EXISTS" || echo "NOT_FOUND"
```

- If `EXISTS`: read the file, show the current values (mask the service key — show only the first 12 characters followed by `…`), and ask: **"A config file already exists. Would you like to update it or keep it as-is?"**
  - If they want to keep it, jump straight to Step 5 (verify connection).
  - If they want to update it, continue from Step 2.
- If `NOT_FOUND`: tell them you'll walk them through creating it now, then continue to Step 2.

---

## Step 2 — Explain What Is Needed

Tell the user the following before asking for any values:

> To use the preflight analysis skill you need three pieces of information. All of them
> come from the Supabase project dashboard — your course director can give you access
> if you don't have it yet.
>
> **1. Supabase Project URL**
> In the Supabase dashboard: open the project → **Project Settings** (gear icon) →
> **API** → copy the **Project URL**. It looks like:
> `https://xxxxxxxxxxxxxxxxxxxx.supabase.co`
>
> **2. Service Role Secret Key**
> On the same API page, under **Project API keys**, click **Reveal** next to
> `service_role`. Copy the full key — it is a long string starting with `eyJ`.
> ⚠️ Keep this secret. It bypasses all row-level security and should never be shared
> or committed to the repo.
>
> **3. Textbook PDF folder path**
> The skill reads textbook pages to ground its analysis. You need the full path to
> the folder on your machine that contains the OpenStax PDF files. Your course director
> can point you to the shared OneDrive folder or a local copy.
>
> Ready? Let's collect them one at a time.

---

## Step 3 — Collect Each Config Value

Ask for each value **one at a time**, validating before moving on.

### 3a. Supabase URL

Ask: **"Paste your Supabase Project URL:"**

Validate:
- Must start with `https://`
- Must end with `.supabase.co`

If invalid, explain what's wrong and ask again. Store as `SUPA_URL`.

### 3b. Service Role Key

Ask: **"Paste your Supabase service_role key:"**

Validate:
- Must be at least 100 characters (it's a JWT)
- Should start with `eyJ`

If it looks like the anon/public key (the same one in `js/config.js`), warn:
> "This looks like the anon key, not the service role key. The service role key is
> much longer and is listed separately under 'service_role' on the API settings page.
> Please double-check and paste it again."

Store as `SUPA_KEY`.

### 3c. Textbook PDF Path

Ask: **"What is the full path to your textbook PDF folder?"**
Add a hint: "(e.g. `/Users/yourname/OneDrive/Physics/Text_Book_PDFs/215 Sections/`)"

After they enter a path, check if the directory exists:

```bash
ls "{path}" 2>/dev/null | head -5
```

- If it exists and has files: show the first few filenames and confirm: "✓ Found that folder."
- If empty or missing: warn — **"That path doesn't seem to exist on this machine. You can still proceed and update it later by re-running `/setup-preflight`."** — but do not block; store whatever they entered.

Store as `PDF_PATH`.

### 3d. Default Course

Ask: **"Which course do you primarily teach?"**
Options: `phys-215` or `phys-110`

Store as `COURSE_ID`.

---

## Step 4 — Write the Config File

Create the directory if it doesn't exist:

```bash
mkdir -p ~/.claude/skills/preflight-analyze
```

Then write the config using a here-doc so special characters in the key are handled safely:

```bash
cat > ~/.claude/skills/preflight-analyze/config.json << 'ENDOFCONFIG'
{
  "supabase_url": "SUPA_URL_PLACEHOLDER",
  "supabase_service_key": "SUPA_KEY_PLACEHOLDER",
  "textbook_base_path": "PDF_PATH_PLACEHOLDER",
  "default_course_id": "COURSE_ID_PLACEHOLDER"
}
ENDOFCONFIG
```

Substitute the actual values for each placeholder before running. Then confirm:

> ✓ Config written to `~/.claude/skills/preflight-analyze/config.json`
> This file lives only on your local machine — it is in `.gitignore` and will never
> be committed to the repo.

---

## Step 5 — Verify the Supabase Connection

Run a quick connection test:

```bash
node -e "
const fs = require('fs'), path = require('path');
const cfg = JSON.parse(fs.readFileSync(path.join(process.env.HOME, '.claude/skills/preflight-analyze/config.json'), 'utf8'));
fetch(cfg.supabase_url + '/rest/v1/courses?select=id,title', {
  headers: { apikey: cfg.supabase_service_key, Authorization: 'Bearer ' + cfg.supabase_service_key }
}).then(r => r.json()).then(d => {
  if (Array.isArray(d) && d.length > 0) {
    console.log('OK');
    d.forEach(c => console.log(c.id + ' | ' + c.title));
  } else {
    console.log('FAIL: ' + JSON.stringify(d));
  }
}).catch(e => console.log('FAIL: ' + e.message));
"
```

**If `OK`:** Show the list of courses returned. Tell the user they're connected.

**If `FAIL` with a 401 or `Invalid API key`:**
> "The service role key wasn't accepted. Please check that you copied the **service_role**
> key (not the **anon** key) from Supabase → Project Settings → API.
> Re-run `/setup-preflight` to update it."

**If `FAIL` with a network/DNS error:**
> "Couldn't reach Supabase. Check that the Project URL is correct and that you have an
> internet connection. Re-run `/setup-preflight` to fix the URL."

---

## Step 6 — Verify the Textbook Path (Optional Spot-Check)

If the PDF path was confirmed in Step 3c, skip this. If it was unconfirmed, remind the user:

> "Your textbook path (`{PDF_PATH}`) wasn't found. The skill will still run but won't
> be able to read reference pages for grounding. When you have the files locally, run
> `/setup-preflight` again to update the path."

---

## Step 7 — Print a Success Summary

Print this summary (substituting real values):

---

> ✅ **Setup complete!**
>
> Your config is saved at `~/.claude/skills/preflight-analyze/config.json`
>
> ---
>
> **Run your first analysis:**
>
> ```
> /preflight-analyze {COURSE_ID} preflight-1 M
> ```
> Analyzes M-day section submissions for Preflight 1, writes suggested scores to
> Supabase (unfinalized), and prints a per-instructor misconception report.
>
> **Other useful commands:**
> ```
> /preflight-analyze {COURSE_ID} preflight-1 T    ← T-day sections only
> /preflight-analyze {COURSE_ID} preflight-1      ← all sections
> /preflight-analyze {COURSE_ID}                  ← pick from a list of assignments
> ```
>
> Suggested scores are always written as **unfinalized** — instructors review and
> click **Finalize & Publish Grades** in the Admin panel when they're ready.
>
> **Admin panel:** https://dfpm-physics.github.io/Core_Preflights/admin.html

---

## Error Handling

- **Node.js not installed**: If the `node` command is not found, tell the user they need
  Node.js installed (https://nodejs.org). The analysis skill also requires Node.js for
  its seed/test scripts, so this is a hard prerequisite.
- **Permission denied writing config**: If `mkdir` or writing the file fails, suggest
  running `mkdir -p ~/.claude/skills/preflight-analyze` manually and checking permissions.
- **User wants to stop**: At any point if the user says "cancel", "stop", or "never mind",
  stop and tell them they can re-run `/setup-preflight` whenever they're ready.
