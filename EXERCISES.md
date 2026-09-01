# TaskFlow — Rails Interview Exercises

Hands-on prep for **Mid/Senior Rails** interviews. The codebase is incomplete on purpose.

## How this exercise works

This is **not** a fill-in-the-blanks tutorial. Each exercise gives you:

1. **A problem** — symptoms, business rules, or broken behavior
2. **Acceptance criteria** — how you know you're done (mostly **failing specs**)
3. **Investigation steps** — where to look, not what to type

**Do not** read `SOLUTIONS.md` or `docs/HINTS.md` until you've attempted the exercise. Hints are tiered (nudge → direction → pointer) for when you're genuinely stuck.

**Read first:** `docs/DOMAIN.md` — product requirements without implementation details.

---

## Workflow for every exercise

```bash
bundle exec rspec          # see what's failing
bin/rails routes           # explore the API surface
bin/rails console          # probe models and associations
tail -f log/development.log  # watch SQL while hitting endpoints
```

You're done when the relevant specs pass and acceptance criteria are met.

---

## Exercise 1: Wire up the domain model
**Time:** 45–60 min | **Topics:** associations, validations, scopes

### The problem

The database schema and seeds describe a project-management app, but the **models don't fully reflect the domain**. Things break when you use the app or run tests.

Try this:

```bash
bundle exec rspec spec/models/
curl -H "X-User-Id: 2" http://localhost:3000/projects   # 500 error
```

In console, explore what works and what raises `NoMethodError`. Read `Project#member?` — it assumes something that isn't defined yet.

### Business rules (from `docs/DOMAIN.md`)

- Users can **own** projects and **join** projects (separate relationships).
- Users can be **assigned** tasks, **create** tasks, and **author** comments.
- Projects have **members** (not just an owner).
- Projects can be filtered by `active` / `archived` status.
- A user should see projects they **own or belong to** (`Project.for_user(user)`).
- Tasks can be filtered: overdue, by status, by assignee.
- New tasks cannot be created with a `due_at` in the past (nil is OK).

### Acceptance criteria

```bash
bundle exec rspec spec/models/user_spec.rb
bundle exec rspec spec/models/project_spec.rb
bundle exec rspec spec/models/task_spec.rb
# All green

curl -H "X-User-Id: 2" http://localhost:3000/projects
# 200 OK with project JSON including members
```

### Investigate

- `db/schema.rb` — foreign keys tell you a lot
- `db/seeds.rb` — how data is actually linked
- `User` already has one association — use it as a pattern

### Interview questions (out loud)

- `has_many :through` vs `has_and_belongs_to_many`?
- `dependent: :destroy` vs `dependent: :delete_all`?
- Scope vs class method?

---

## Exercise 2: The slow endpoints
**Time:** 45 min | **Topics:** N+1, eager loading, counter cache, indexes

### The problem

With seed data the app feels fine. Imagine **50 projects**, each with **20 tasks** and **5 members** — `GET /projects` and `GET /projects/:id/tasks` would crawl.

Your job: find the performance problems and fix them so query count stays **bounded** as data grows.

### Acceptance criteria

- `GET /projects` and task index don't fire redundant queries per row (verify via `log/development.log` or console subscriber).
- Project JSON exposes task count **without** querying `tasks` on every row.
- New migration adds sensible indexes for how tasks are filtered in `TasksController#index`.

### Investigate

- Trace `serialize_project` and `serialize_task` — what association methods get called per record?
- Compare `project.tasks.count` vs a column on `projects`.
- Which columns appear in `WHERE` clauses?

### Interview questions

- Explain N+1 using this app as the example.
- `includes` vs `preload` vs `eager_load`?
- Counter cache trade-offs?

---

## Exercise 3: Multi-step operations belong together
**Time:** 1 hour | **Topics:** service objects, transactions

### The problem

**Creating a project** today saves one row. Seeds manually add an owner membership — but the API doesn't. If step two failed, you'd have orphan data.

**Assigning a task** updates one column but business rules say only project members can be assignees. Notification happens inside a model callback during the request.

Stub classes exist under `app/services/` but raise `NotImplementedError`.

### Acceptance criteria

- `POST /projects` creates project **and** owner membership atomically.
- `PATCH .../tasks/:id/assign` rejects non-members with a sensible HTTP error.
- Assignment notification is **not** triggered synchronously in the model callback (job can come in Exercise 6).
- Controllers delegate to services; they stay thin.

### Investigate

- `ProjectsController#create`, `TasksController#assign`
- `Task` and `ProjectMembership` models — anything blocking the request thread?

### Interview questions

- Service object vs model method?
- What belongs inside a transaction?

---

## Exercise 4: Complete the API
**Time:** 1 hour | **Topics:** REST, pagination, HTTP semantics

### The problem

`bin/rails routes` shows more than the controllers implement. Some actions are missing; list endpoints return everything with no pagination.

### Acceptance criteria

- Full CRUD for projects and tasks where routes exist.
- Correct status codes: 201 create, 204 delete, 422 validation errors, etc.
- Project index supports pagination (`?page=`, `?per_page=`).
- JSON error shape is consistent.

### Investigate

```bash
bin/rails routes | grep -E 'project|task'
```

Compare to controller action list.

### Interview questions

- What makes an API RESTful?
- 422 vs 400 vs 403?

---

## Exercise 5: Who is allowed to do what?
**Time:** 45 min | **Topics:** Pundit, authorization

### The problem

Any logged-in user can access any project by guessing IDs. Product rules are in `docs/DOMAIN.md` (authorization table).

Pundit is installed and wired in `ApplicationController`. Policies raise `NotImplementedError`.

### Acceptance criteria

- Non-members get **403** on projects they don't belong to.
- Index only shows projects the current user may see.
- Task mutations respect membership roles (`can_manage_tasks?`).

### Investigate

- `app/policies/`
- `authorize` and `policy_scope` in Pundit docs

### Interview questions

- Pundit vs CanCanCan?
- Authorization in controller vs service?

---

## Exercise 6: Stop blocking the request thread
**Time:** 45 min | **Topics:** ActiveJob, idempotency

### The problem

Something makes assign and membership-create requests slower than they should be. Side effects run **during** the HTTP request.

### Acceptance criteria

- `Tasks::AssignmentNotificationJob` implemented and enqueued on assign.
- Job is safe to run twice (idempotent).
- `ProjectMembership` creation no longer calls `sleep` in a callback.

### Investigate

- Search codebase for `sleep`
- `app/jobs/`

### Interview questions

- ActiveJob vs Sidekiq?
- Why idempotency matters?

---

## Exercise 7: Prove it with tests
**Time:** 1–1.5 hours | **Topics:** RSpec

### The problem

Model specs from Exercise 1 should already pass. Request and service specs are still `pending`.

### Acceptance criteria

```bash
bundle exec rspec
# 0 failures (pending OK only if you deliberately defer bonus items)
```

Cover: auth headers, CRUD happy paths, 401/403 cases, service rollback on failure.

### Interview questions

- Model vs request spec?
- What to mock vs hit the DB?

---

## Exercise 8: The search endpoint
**Time:** 30 min | **Topics:** security

### The problem

QA filed a ticket: user search might behave strangely with certain input. No further details.

### Acceptance criteria

```bash
curl "http://localhost:3000/users/search?q=' OR '1'='1"
# Must not leak data or behave like a raw SQL concat attack
```

Audit strong params while you're at it.

### Interview questions

- SQL injection in Rails?
- Strong parameters history?

---

## Exercise 9: Comments on more than tasks
**Time:** 1 hour | **Topics:** query objects, polymorphism

### The problem

1. Task filtering logic lives inline in the controller — hard to test and reuse.
2. Product wants comments on **projects** too, not only tasks.

Stub: `app/queries/tasks/filter_query.rb`.

### Acceptance criteria

- `Tasks::FilterQuery` supports optional filters: status, assignee, tag, overdue, priority, sort.
- Comments use a polymorphic parent; existing task comments still work after migration.

### Investigate

- `TasksController#index` filtering
- `Comment` model and schema

### Interview questions

- Query object vs scope?
- Polymorphic vs STI?

---

## Exercise 10: Explicit beats magic
**Time:** 45 min | **Topics:** design judgment

### The problem

The team debates whether model callbacks for side effects are maintainable. Make the flow **explicit** and document the decision.

### Acceptance criteria

- No `sleep` in model callbacks.
- Side effects triggered from services/jobs only.
- Short note in `docs/` explaining why (ADR style, half page max).

### Interview questions

- "Callbacks are evil" — agree or disagree?

---

## When you're stuck

1. Re-read acceptance criteria and failing spec output.
2. Open `docs/HINTS.md` — **one level only**.
3. Last resort: `SOLUTIONS.md` for that exercise only.

---

## Final checklist

- [ ] Draw ER diagram from memory
- [ ] Trace: route → controller → policy → service → model → DB
- [ ] Spot N+1 without hints
- [ ] Explain service vs callback trade-off with examples from this app
- [ ] Write a request spec from scratch

## Resources

- `docs/DOMAIN.md` — business rules
- `docs/THEORY_QUESTIONS.md` — verbal prep
- `docs/MOCK_INTERVIEW_SCRIPT.md` — practice with a partner
- `docs/RAILS_CHEATSHEET.md` — syntax reference (not exercise answers)
- `SOLUTIONS.md` — answer key
