# Rails Mid/Senior Interview — Theory Questions

Use these for verbal practice, whiteboard discussions, or pair-study sessions. Answers are intentionally brief — your friend should expand with examples from the TaskFlow exercise.

---

## Ruby fundamentals

1. **What is the difference between `==`, `===`, and `eql?`?**
2. **Explain `include` vs `extend` vs `prepend`.**
3. **What are modules used for in Ruby?**
4. **Blocks, procs, and lambdas — differences?**
5. **What is the method lookup path (ancestors chain)?**
6. **Explain `self` in different contexts.**
7. **What are keyword arguments? How did they change in Ruby 2.7/3.0?**
8. **Mutable vs immutable — which Ruby objects are frozen by default?**
9. **What is `Enumerable`? Name 5 useful methods.**
10. **Explain exception handling: `rescue`, `ensure`, custom exceptions.**

---

## Rails architecture

1. **Describe the request/response cycle in Rails.**
2. **MVC — what belongs in each layer?**
3. **What are concerns? When should you use them?**
4. **Explain the Rails autoloading (Zeitwerk) basics.**
5. **What is the difference between a Rails engine and a gem?**
6. **How does `config.load_defaults` work across Rails versions?**
7. **API-only vs full-stack Rails — middleware differences?**

---

## Active Record deep dive

1. **Lifecycle of `User.create(name: "A")` — what happens step by step?**
2. **`save` vs `save!` vs `create` vs `create!`**
3. **`update` vs `update_attribute` vs `update_column` — pitfalls?**
4. **Optimistic vs pessimistic locking.**
5. **`find` vs `find_by` vs `where().first`**
6. **What is `inverse_of` and why use it?**
7. **Database transactions — when are they rolled back?**
8. **`joins` vs `includes` vs `left_outer_joins`**
9. **Explain `counter_cache` and `touch: true`.**
10. **What are database indexes? When to add / avoid?**
11. **Migrations in production — safe patterns (strong_migrations).**
12. **N+1 problem — detection and fixes.**

---

## Design patterns in Rails

1. **Service objects — naming, interface, return values.**
2. **Form objects — when better than model validations?**
3. **Query objects vs scopes.**
4. **Presenter/Decorator vs helper vs serializer.**
5. **Repository pattern — needed in Rails?**
6. **Callbacks — appropriate uses vs anti-patterns.**
7. **Domain-driven design in Rails apps — practical tips.**

---

## API & HTTP

1. **REST principles — resources, verbs, status codes.**
2. **Idempotent HTTP methods.**
3. **JWT vs session cookies for API auth.**
4. **GraphQL vs REST — trade-offs.**
5. **Serialization: ActiveModel::Serializers, Alba, Jbuilder, jsonapi-serializer.**
6. **Pagination strategies (offset vs cursor).**
7. **CORS — what problem does it solve?**

---

## Testing

1. **Testing pyramid in Rails context.**
2. **Factories vs fixtures.**
3. **How to test background jobs.**
4. **Stubbing vs mocking — guidelines.**
5. **`let` vs `let!` vs instance variables in RSpec.**
6. **Request specs vs controller specs (legacy).**
7. **VCR / WebMock for external APIs.**

---

## Performance & scaling

1. **Caching layers: page, action, fragment, low-level.**
2. **Russian doll caching.**
3. **Background job queues (Sidekiq, Solid Queue).**
4. **Read replicas — how does Rails support them?**
5. **Connection pooling (`pool` in database.yml).**
6. **Memory bloat in Puma workers — common causes.**
7. **Profiling tools: rack-mini-profiler, memory_profiler, stackprof.**

---

## Security

1. **CSRF — relevant for APIs?**
2. **SQL injection, XSS, mass assignment.**
3. **`has_secure_password` and bcrypt.**
4. **Rate limiting and brute force protection.**
5. **Secrets management (credentials, ENV).**
6. **Brakeman / bundler-audit — what do they find?**

---

## Behavioral / system design (common at senior level)

1. **Design a URL shortener / notification system / rate limiter in Rails.**
2. **How would you migrate a monolith to services?**
3. **Describe a production incident you debugged.**
4. **How do you approach technical debt?**
5. **Code review — what do you look for?**
6. **How do you mentor junior developers?**

---

## Sample "live coding" prompts

Interviewers often ask to implement one of these in 20–40 minutes:

1. Build a `BookCheckout` service with overdue fine calculation.
2. Write a scope that finds users who haven't logged in for 30 days.
3. Refactor a fat controller action into service + policy.
4. Fix an N+1 and write a spec proving it's fixed.
5. Implement soft deletes with `deleted_at` and default scope pitfalls.

TaskFlow exercises 1–3 and 7 map directly to prompts 2–5.

---

## How to practice verbally

For each question:

1. **Answer in 60–90 seconds** (interview pace).
2. **Give a concrete example** from TaskFlow or past work.
3. **Mention trade-offs** — interviewers love "it depends."
4. **Ask a clarifying question** if the prompt is ambiguous (shows senior judgment).
