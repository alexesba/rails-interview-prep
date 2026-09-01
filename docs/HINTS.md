# Hints (use only when stuck)

Read each level **one at a time**. Try to solve the exercise before opening the next level.

Levels: **Nudge** → **Direction** → **Pointer** (file/ concept only, never full code)

---

## Exercise 1 — Active Record foundations

**Nudge:** Run `bundle exec rspec spec/models/` — failing examples describe expected behavior. Explore `db/schema.rb` and sketch relationships on paper.

**Direction:** A user relates to projects in two different ways (ownership vs membership). Tasks reference users in two different foreign keys. `Project#member?` already encodes business logic but something it calls doesn't exist yet.

**Pointer:** Look at foreign keys in `schema.rb` for `users`, `projects`, `project_memberships`, `tasks`, and `comments`. Mirror patterns already used on `User` for `owned_projects`.

---

## Exercise 2 — Performance

**Nudge:** Hit `GET /projects` with query logging on (`ActiveRecord::Base.logger = Logger.new($stdout)` in console, or check `log/development.log`). Count SQL statements. Does it grow with the number of projects?

**Direction:** Serialization calls association methods in a loop. Some counts could be stored on the parent row instead of queried each time. Filter columns used in `WHERE` clauses often need database indexes.

**Pointer:** `ProjectsController#serialize_project`, `TasksController#serialize_task`. Research: `includes`, `counter_cache`, `add_index`.

---

## Exercise 3 — Service objects

**Nudge:** Creating a project today only saves the project row — seeds manually add an owner membership. What happens if membership creation fails? Read `ProjectsController#create` and `TasksController#assign`.

**Direction:** Multi-step writes that must succeed or fail together belong in a transaction. Side effects after a successful write should not block the response.

**Pointer:** Files under `app/services/`. Controllers should stay thin.

---

## Exercise 4 — REST API

**Nudge:** Run `bin/rails routes`. Compare available routes to what `ProjectsController` and `TasksController` actually implement.

**Direction:** REST uses the right HTTP verb and status for each outcome. List endpoints on large tables need pagination.

**Pointer:** Kaminari is already in the Gemfile. Check which actions are missing vs routes.

---

## Exercise 5 — Authorization

**Nudge:** Right now any authenticated user can hit any project by ID. Re-read authorization table in `docs/DOMAIN.md`.

**Direction:** Pundit is wired in `ApplicationController`. Policy classes raise `NotImplementedError` — that's your starting point.

**Pointer:** `app/policies/project_policy.rb`, `authorize`, `policy_scope`.

---

## Exercise 6 — Background jobs

**Nudge:** Assign a task and watch the request time in logs — something synchronous happens on update. `ProjectMembership` has the same smell.

**Direction:** Jobs should be safe to run more than once for the same event. Check current assignee before notifying.

**Pointer:** `app/jobs/tasks/assignment_notification_job.rb`, ActiveJob test adapter.

---

## Exercise 7 — Testing

**Nudge:** Replace `pending` examples in `spec/` with real tests. Use factories in `spec/factories.rb`.

**Direction:** Test behavior, not implementation. Request specs prove the HTTP contract; model specs prove domain rules.

**Pointer:** Existing pending specs list the minimum coverage expected.

---

## Exercise 8 — Security

**Nudge:** Try the search endpoint with an unusual `q` parameter (see `EXERCISES.md` verify section). Read how the query is built.

**Direction:** Never interpolate user input into SQL strings. ActiveRecord has safer alternatives.

**Pointer:** `UsersController#search`.

---

## Exercise 9 — Query object & polymorphism

**Nudge:** `TasksController#index` filters inline — hard to test and reuse. Comments only attach to tasks but product wants project comments too.

**Direction:** Extract filtering to a single callable object. Polymorphic associations use `_type` and `_id` columns.

**Pointer:** `app/queries/tasks/filter_query.rb`, `Comment` model and migration history.

---

## Exercise 10 — Callbacks vs services

**Nudge:** Find `sleep` in models. Would you want that running on every save in production?

**Direction:** Make side effects explicit and async. Document the decision for future teammates.

**Pointer:** `Task`, `ProjectMembership`, and the services/jobs from Exercises 3 and 6.
