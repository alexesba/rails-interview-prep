# Rails Mid/Senior Interview Prep

A hands-on exercise for developers preparing for **Mid to Senior Ruby on Rails** interviews.

Work on **TaskFlow** — a small project-management API. The codebase is **incomplete on purpose**: models, performance, security, and architecture gaps mirror real interview scenarios. **Solutions are not spelled out in the code** — failing specs and `docs/DOMAIN.md` define what "done" looks like.

## Quick start

```bash
bundle install
bin/rails db:setup
bin/rails db:seed
bin/rails server
```

**Authentication (simplified for the exercise):** send the user ID in a header:

```bash
curl -H "X-User-Id: 2" http://localhost:3000/projects
```

After seeding, check the console output for user IDs.

> **Note:** The API errors until Exercise 1 is done. Run `bundle exec rspec spec/models/` — failing tests describe what to build. There are no commented-out answers in the models.

## How to use this exercise

1. Read `docs/DOMAIN.md` — product requirements without implementation hints.
2. Work through `EXERCISES.md` — problems and acceptance criteria only.
3. Run `bundle exec rspec` after each exercise — tests define expected behavior.
4. If stuck: `docs/HINTS.md` (one level at a time), then `SOLUTIONS.md` as last resort.
5. Review `docs/THEORY_QUESTIONS.md` for verbal prep.
6. Run `docs/MOCK_INTERVIEW_SCRIPT.md` with a partner.
7. Use `docs/RAILS_CHEATSHEET.md` for syntax, not answers.

## Topics covered

| Area | What they'll practice |
|------|------------------------|
| Active Record | Associations, validations, scopes, enums, transactions |
| Performance | N+1 queries, eager loading, counter caches, indexes |
| Architecture | Service objects, query objects, fat model vs skinny controller |
| API design | REST, strong params, error handling, pagination |
| Authorization | Pundit policies, role-based access |
| Background jobs | ActiveJob, idempotency, moving logic out of callbacks |
| Testing | RSpec, factories, model/request/service specs |
| Security | SQL injection, mass assignment, authorization |
| Advanced AR | Polymorphic associations, query objects |
| Design judgment | Callbacks vs services, when to extract objects |

## Suggested study plan

| Day | Focus | Time |
|-----|-------|------|
| 1 | Exercises 1–3 (Models, N+1, Services) | 2–3 h |
| 2 | Exercises 4–6 (API, Auth, Jobs) | 2–3 h |
| 3 | Exercises 7–10 (Tests, Security, Advanced) | 2–3 h |
| 4 | Theory questions + mock interview (`docs/MOCK_INTERVIEW_SCRIPT.md`) | 1–2 h |

## Mock interview tip

After finishing, explain choices out loud as if in a live interview:

- "Why a service object here instead of a callback?"
- "How would this behave under load with 10k tasks?"
- "What would you test first and why?"

Good luck!
