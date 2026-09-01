# Mock Interview Script

Use this to run a **45–60 minute** mock interview for a Mid/Senior Rails role. One person is the **Interviewer**, the other is the **Candidate**.

The candidate should have completed at least Exercises 1–6 in TaskFlow (or be familiar with the codebase).

---

## Before you start

- [ ] Candidate has TaskFlow running locally (`bin/rails server`)
- [ ] Candidate has read `docs/DOMAIN.md` and attempted Exercises 1–6
- [ ] Candidate has `EXERCISES.md` open but **not** `SOLUTIONS.md` or `docs/HINTS.md`
- [ ] Interviewer reads this script; candidate does not
- [ ] Set a timer (phone or [timer tab](https://www.google.com/search?q=timer))
- [ ] Decide: **remote-style** (screen share) or **in-person** (laptop + whiteboard)

**Scoring tip:** Mid/Senior interviews weight **reasoning and trade-offs** over perfect syntax. Note when the candidate asks clarifying questions — that's a senior signal.

---

## Interview structure (60 min)

| Block | Time | Type |
|-------|------|------|
| Warm-up & background | 5 min | Verbal |
| Ruby & Rails fundamentals | 10 min | Verbal |
| Live coding — TaskFlow | 25 min | Hands-on |
| System design light | 10 min | Whiteboard / verbal |
| Candidate questions | 5 min | Verbal |
| Debrief (optional) | 5 min | Feedback |

Short version (45 min): skip Block 4 or cut Block 2 to 5 min.

---

## Block 1 — Warm-up (5 min)

> *"Thanks for joining. Tell me about a Rails project you worked on recently — what was your role and what was the hardest technical problem you solved?"*

**Listen for:**
- Specificity (not vague "we used Rails")
- Ownership ("I designed…" vs "the team did…")
- Problem → approach → outcome

**Follow-up (pick one):**
- "What would you do differently today?"
- "How did you test that solution?"

---

## Block 2 — Ruby & Rails fundamentals (10 min)

Ask **3–4 questions**. Don't rapid-fire all of them.

### Q1 — Associations (2 min)
> *"In TaskFlow, a User can own projects and also be a member of projects. How would you model that in Active Record?"*

**Strong answer mentions:** `has_many :owned_projects`, `has_many :project_memberships`, `has_many :projects, through: :project_memberships`, join table with `role`.

### Q2 — N+1 (3 min)
> *"Our `/projects` endpoint is slow with 50 projects. Walk me through how you'd debug and fix it."*

**Strong answer mentions:** log queries, Bullet gem, `includes`/`preload`, `counter_cache`, avoid `.count` in loops, benchmark before/after.

### Q3 — Callbacks (2 min)
> *"We send an email when a task is assigned, currently in an `after_update` callback. What's wrong with that?"*

**Strong answer mentions:** hidden side effects, hard to test, blocks request, ordering issues, prefer service + background job, idempotency.

### Q4 — Transactions (3 min)
> *"Creating a project should also create an owner membership. What happens if the membership save fails after the project saves?"*

**Strong answer mentions:** `ActiveRecord::Base.transaction`, rollback, `create!` vs `create`, service object wrapping both.

**Interviewer notes:**

| Score | Signal |
|-------|--------|
| ⭐⭐⭐ | Concrete examples from TaskFlow, mentions trade-offs |
| ⭐⭐ | Correct concepts, generic examples |
| ⭐ | Memorized definitions, can't apply to TaskFlow |

---

## Block 3 — Live coding (25 min)

Pick **one primary task** and **one follow-up**. Candidate codes in TaskFlow; interviewer observes and probes.

### Option A — Fix N+1 (recommended, 15 min + 10 min follow-up)

> *"Open `ProjectsController#index`. It's slow in production. Fix the performance issue and explain each change."*

**Expected work:**
- Add `includes(:owner, project_memberships: :user)` (or equivalent)
- Replace `project.tasks.count` with `tasks_count` (counter cache) OR eager load tasks
- Explain query count before/after

**Follow-up (10 min):**
> *"Write an RSpec example that would catch this regression."*

**Probe questions while they code:**
- "How many queries do you expect now?"
- "What if we also need comment counts per task?"
- "Would you use `preload` or `eager_load` here? Why?"

---

### Option B — Service object (15 min + 10 min follow-up)

> *"Implement `Tasks::Assigner` so that only project members can be assigned, and enqueue a notification job instead of using the model callback."*

**Expected work:**
- Membership check via `project.member?(assignee)`
- Transaction around update
- `Tasks::AssignmentNotificationJob.perform_later`
- Wire into `TasksController#assign`

**Follow-up:**
> *"What error should we return if assignee is not a member? What HTTP status?"*

**Strong answer:** 422 Unprocessable Entity or 403 Forbidden with clear JSON error; discuss preference.

---

### Option C — Security fix (10 min + 15 min auth)

> *"Security review flagged `UsersController#search`. Fix it."*

**Expected work:** Parameterized query, `sanitize_sql_like`, no string interpolation in SQL.

**Follow-up (15 min):**
> *"Implement `ProjectPolicy#show?` so only members and admins can view a project."*

---

### Option D — Query object (20 min)

> *"Implement `Tasks::FilterQuery` to support filtering by status, assignee, overdue, tag, and sorting by due date."*

**Probe:** "When is a query object better than adding more scopes?"

---

### Live coding rubric

| Criteria | 1 (weak) | 3 (solid) | 5 (strong) |
|----------|----------|-----------|------------|
| Clarifying questions | Jumps in blindly | Asks 1–2 questions | Restates requirements, confirms edge cases |
| Code quality | Works but messy | Clean, idiomatic Rails | Extracts helpers, names well, minimal scope |
| Testing mindset | No mention of tests | Mentions what to test | Writes or sketches a spec |
| Communication | Silent coding | Explains steps | Narrates trade-offs in real time |
| Debugging | Stuck without logs | Uses console/logs | Systematic: reproduce → isolate → fix |

---

## Block 4 — System design light (10 min)

Pick **one**. Candidate talks through approach; no full implementation required.

### SD1 — Notification system
> *"TaskFlow needs to notify users via email, Slack, and in-app when they're assigned a task. Design the architecture."*

**Listen for:**
- Event or service layer (not callbacks everywhere)
- Background jobs per channel
- Idempotency, retries, dead letter queue
- Preference store (user opts out of Slack)
- Optional: `Noticed` gem, ActiveSupport::Notifications

### SD2 — Scaling reads
> *"We have 2 million tasks. The project dashboard loads all tasks. How do you fix it?"*

**Listen for:**
- Pagination (Kaminari, cursor-based)
- Indexes on filter columns
- Caching (fragment, low-level)
- Read replicas
- Avoid loading full collections in index

### SD3 — Multi-tenancy
> *"We need to sell TaskFlow to companies — each company's data must be isolated. Options?"*

**Listen for:**
- Row-level: `account_id` on all tables + default scope / policy scope
- Schema-per-tenant vs DB-per-tenant trade-offs
- `acts_as_tenant` or similar
- Leaky abstractions risk with default_scope

**Whiteboard prompt:** Draw boxes for Controller → Policy → Service → Job → DB.

---

## Block 5 — Candidate questions (5 min)

> *"Do you have any questions for us?"*

**Good candidate questions (examples):**
- Team structure and code review culture
- Rails version, test coverage expectations
- On-call / incident process
- Biggest technical debt on the team

**Interviewer:** Answer honestly or role-play a fictional company.

---

## Block 6 — Debrief (5 min, optional)

Give **2 positives** and **1 growth area**. Example:

> *"You nailed the N+1 diagnosis and knew to use counter_cache without prompting. Your service object was clean. Growth area: pause to write a test sketch before coding — interviewers love seeing TDD instincts even under time pressure."*

---

## Rapid-fire round (bonus, 10 min)

Use if you have extra time or want a second session.

| # | Question | Time |
|---|----------|------|
| 1 | `includes` vs `joins`? | 1 min |
| 2 | `save` vs `save!`? | 30 sec |
| 3 | What is strong parameters? | 1 min |
| 4 | Puma vs Sidekiq — what does each do? | 1 min |
| 5 | How does `dependent: :destroy` work? | 1 min |
| 6 | Optimistic vs pessimistic locking? | 2 min |
| 7 | What is STI? | 1 min |
| 8 | How do you deploy a migration safely in production? | 2 min |

---

## Second mock interview (advanced)

After the candidate completes all 10 exercises, run a **harder** 60 min session:

1. **No TaskFlow** — pure whiteboard: design a booking system (models, APIs, race conditions on double-booking).
2. **Pair on Exercise 9** — polymorphic comments migration on a production DB with zero downtime (expand on `strong_migrations`).
3. **Debugging scenario:** Give them a log snippet with 500 errors and 200 SQL queries per request; they explain root cause.
4. **Behavioral:** "Tell me about a time you disagreed with a technical decision."

---

## Interviewer cheat sheet — red flags vs green flags

### Red flags
- Can't explain their own code from Exercises 1–3
- Uses `eval` or string SQL without concern
- Puts business logic only in controllers with no extraction plan
- Never mentions tests
- "I'd just add a gem" without understanding what it does

### Green flags
- Asks about requirements before coding
- Mentions edge cases unprompted (nil assignee, archived project)
- Discusses trade-offs unprompted
- Knows when **not** to use a pattern (e.g. "this service object would be overkill for a one-liner")
- Comfortable saying "I'd look up the exact syntax but the approach is…"

---

## Scheduling template (copy-paste to your friend)

```
Mock Interview — Rails Mid/Senior
Date: ___________
Duration: 60 min
Format: Video / In person

You'll need:
- TaskFlow repo running locally
- Exercises 1–6 attempted (doesn't need to be perfect)
- Screen share ready

Agenda:
- 5 min intro
- 10 min Ruby/Rails questions
- 25 min live coding in TaskFlow
- 10 min system design discussion
- 5 min your questions
- 5 min feedback

I'll play interviewer. No SOLUTIONS.md during the session!
```

---

Good luck — run this twice with a few days between sessions for best results.
