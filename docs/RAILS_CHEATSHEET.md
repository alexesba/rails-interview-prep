# Rails Mid/Senior Cheat Sheet

Quick reference for interview prep. Pair with TaskFlow exercises and `THEORY_QUESTIONS.md`.

---

## Active Record queries

```ruby
# Finders
User.find(1)              # raises if missing
User.find_by(email: "a")  # nil if missing
User.where(active: true)  # relation (lazy)

# Eager loading (fix N+1)
Project.includes(:tasks, :owner)
Project.preload(:tasks)           # separate queries
Project.eager_load(:tasks)        # LEFT OUTER JOIN
Project.left_joins(:tasks).where(tasks: { status: "done" })

# Aggregation
User.count
User.distinct.count
Task.group(:status).count

# Pluck (skip AR objects)
User.pluck(:id, :email)

# Exists (faster than any?)
project.tasks.exists?(status: "todo")
```

| Method | SQL | Use when |
|--------|-----|----------|
| `includes` | Smart preload/eager_load | Default choice for associations |
| `preload` | Separate queries | Always separate queries, no WHERE on assoc |
| `eager_load` | LEFT OUTER JOIN | Need to filter/order on associated table |
| `joins` | INNER JOIN | Filtering only, don't need assoc data loaded |
| `left_joins` | LEFT OUTER JOIN | Include records without association |

---

## Save / update / destroy

```ruby
user.save              # false on failure
user.save!             # raises ActiveRecord::RecordInvalid
user.update(attrs)     # validations run
user.update_column(:name, "x")   # skips validations, callbacks, updated_at
user.update_columns(name: "x", email: "y")
user.touch               # updates updated_at only
user.destroy             # callbacks + dependent
user.delete              # SQL DELETE, no callbacks
```

**Interview gotcha:** `update_attribute` (singular) is deprecated — use `update` or `update_column`.

---

## Validations & callbacks

```ruby
validates :email, presence: true, uniqueness: { case_sensitive: false }
validates :due_at, comparison: { greater_than: Time.current }, on: :create

validate :custom_method

before_validation :normalize_email
after_commit :send_welcome_email, on: :create  # prefer over after_create for jobs
```

| Callback | Risk |
|----------|------|
| `before_save` | Can halt chain with `throw :abort` |
| `after_save` | Runs inside same transaction; external I/O blocks request |
| `after_commit` | Safer for jobs/emails (runs after DB commit) |

**Rule of thumb:** Side effects (email, HTTP, Slack) → **service + job**, not model callback.

---

## Associations cheat sheet

```ruby
# One-to-many
class Project < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_many :tasks, dependent: :destroy
end

# Many-to-many (prefer has_many :through)
has_many :project_memberships
has_many :members, through: :project_memberships, source: :user

# Polymorphic
belongs_to :commentable, polymorphic: true
has_many :comments, as: :commentable

# Self-referential
belongs_to :manager, class_name: "User", optional: true
has_many :reports, class_name: "User", foreign_key: :manager_id

# Options you'll be asked about
belongs_to :assignee, optional: true      # Rails 5+ required by default
has_many :tasks, inverse_of: :project     # keeps in-memory objects in sync
```

| `dependent:` option | Behavior |
|---------------------|----------|
| `:destroy` | Calls `destroy` on each child (callbacks run) |
| `:delete_all` | SQL DELETE, fast, no callbacks |
| `:nullify` | Sets FK to NULL |
| `:restrict_with_error` | Prevents delete if children exist |

---

## Scopes & query objects

```ruby
# Scope
scope :active, -> { where(status: "active") }
scope :for_user, ->(user) { where(user_id: user.id) }  # lambda required for args

# Class method (equivalent)
def self.overdue
  where("due_at < ?", Time.current).where.not(status: "done")
end

# Merge scopes
Task.active.overdue.assigned_to(user)
```

**When to extract a Query Object:** 4+ optional filters, sorting, pagination logic, reused across controllers/reports.

---

## Transactions & locking

```ruby
ActiveRecord::Base.transaction do
  project = Project.create!(name: "Sprint")
  ProjectMembership.create!(project: project, user: owner, role: "owner")
end

# Row lock (pessimistic)
task.with_lock do
  task.update!(status: "done")
end

# Optimistic (add lock_version column)
# raises ActiveRecord::StaleObjectError on conflict
```

**Gotcha:** `rescue` inside a transaction doesn't rollback unless you re-raise. Use `transaction requires_new: true` for nested transactions (savepoints).

---

## Migrations — safe patterns

```ruby
# Add column with default (Postgres) — avoid full table lock on large tables
add_column :tasks, :priority, :integer, default: 0, null: false

# Add index concurrently (Postgres, strong_migrations)
add_index :tasks, :status, algorithm: :concurrently

# Backfill in batches (production)
Task.in_batches.update_all(priority: 0)
```

| Dangerous in production | Safer approach |
|------------------------|----------------|
| `change_column` on big table | Add new column, backfill, swap |
| Non-concurrent index | `algorithm: :concurrently` |
| `add_column` + default on PG < 11 huge table | Multi-step migration |

---

## Controllers & strong params

```ruby
def create
  @project = Project.new(project_params)
  # ...
end

private

def project_params
  params.require(:project).permit(:name, :description, :status)
end
```

**Never:** `params.permit!` in production APIs.

**Mass assignment history:** Rails 3 `attr_accessible` → Rails 4+ strong parameters.

---

## HTTP status codes (API)

| Code | When |
|------|------|
| 200 | OK (GET, PATCH success) |
| 201 | Created (POST success) |
| 204 | No content (DELETE success) |
| 400 | Bad request (malformed JSON) |
| 401 | Not authenticated |
| 403 | Authenticated but not authorized |
| 404 | Resource not found |
| 422 | Validations failed |
| 429 | Rate limited |
| 500 | Server error (avoid exposing details) |

---

## Pundit quick reference

```ruby
# Controller
authorize @project
@projects = policy_scope(Project)

# Policy
class ProjectPolicy < ApplicationPolicy
  def update?
    user.admin? || record.owner_id == user.id
  end

  class Scope < Scope
    def resolve
      scope.where(owner_id: user.id)
    end
  end
end
```

Test policies in isolation: `expect(described_class.new(user, project).update?).to be true`

---

## Background jobs

```ruby
class NotifyJob < ApplicationJob
  queue_as :default
  retry_on Net::OpenTimeout, wait: 5.seconds, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user  # idempotent guard
    # ...
  end
end

# Enqueue
NotifyJob.perform_later(user.id)

# Test
expect { described_class.perform_later(1) }.to have_enqueued_job(NotifyJob)
```

| Adapter | Use |
|---------|-----|
| `:async` | Dev/test (in-memory) |
| `:test` | RSpec job assertions |
| Sidekiq / Solid Queue | Production |

---

## Testing (RSpec)

```ruby
# Model
RSpec.describe Task, type: :model do
  it { is_expected.to validate_presence_of(:title) }  # shoulda-matchers

  describe ".overdue" do
    let!(:overdue_task) { create(:task, due_at: 1.day.ago) }
    it { expect(described_class.overdue).to include(overdue_task) }
  end
end

# Request
RSpec.describe "Projects", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "X-User-Id" => user.id } }

  it "returns projects" do
    get projects_path, headers: headers
    expect(response).to have_http_status(:ok)
  end
end

# let vs let!
let(:user) { create(:user) }   # lazy
let!(:project) { create(:project) }  # created before each example
```

**Avoid:** Testing Rails internals or private methods directly. Test behavior.

---

## Security gotchas

```ruby
# BAD — SQL injection
User.where("name = '#{params[:name]}'")

# GOOD
User.where("name = ?", params[:name])
User.where(name: params[:name])
User.where("name LIKE ?", "%#{sanitize_sql_like(params[:q])}%")

# XSS — mostly relevant for HTML views
# <%= user.name %>  safe (escaped)
# <%== user.bio %>  dangerous (raw HTML)
```

| Threat | Rails defense |
|--------|---------------|
| SQL injection | Parameterized queries, ActiveRecord |
| Mass assignment | Strong parameters |
| CSRF | `protect_from_forgery` (HTML forms; APIs often skip with token auth) |
| Session hijacking | `secure`, `httponly` cookies |

---

## Caching

```ruby
# Low-level
Rails.cache.fetch("project/#{id}/stats", expires_in: 5.minutes) do
  expensive_calculation
end

# Russian doll (views)
# cache [@project, @project.tasks] do ... end

# Cache key with updated_at
cache_key = "project-#{project.id}-#{project.updated_at.to_i}"
```

**Gotcha:** `Rails.cache` in dev is often `:null_store` unless `config.action_controller.perform_caching = true`.

---

## Common interview gotchas

### 1. `class << self` vs `def self.method`
Both define class methods. `class << self` groups many class methods.

### 2. `||=` vs `+=` on hashes
`hash[:key] ||= []` is idiomatic for default arrays.

### 3. `Time.current` vs `Time.now`
Use `Time.current` in Rails — respects `config.time_zone`.

### 4. `find_each` vs `each`
`find_each` batches (default 1000) — use for large tables, not `User.all.each`.

### 5. Default scope
```ruby
default_scope { where(deleted_at: nil) }  # often regretted
# Prefer explicit: scope :kept, -> { where(deleted_at: nil) }
```

### 6. `enum`
```ruby
enum :status, { todo: 0, done: 1 }
# task.todo!  task.done?  Task.todo
```

### 7. Counter cache
```ruby
belongs_to :project, counter_cache: true
# needs projects.tasks_count column
# reset: Project.reset_counters(id, :tasks)
```

### 8. `inverse_of`
Keeps `project.tasks << task` and `task.project` in sync without extra queries.

### 9. STI vs polymorphic
| | STI | Polymorphic |
|---|-----|-------------|
| Table | Single table, `type` column | FK + `type` on child |
| Use | Subtypes share most columns | Comment on Task or Project |
| Risk | Wide sparse table | Can't DB-enforce FK to one parent |

### 10. `reload` vs `reset`
`user.reload` — refetch from DB. `association.reset` — clear cached association.

---

## Performance checklist

- [ ] N+1 fixed with `includes` / `preload`
- [ ] Indexes on WHERE/ORDER BY columns
- [ ] `counter_cache` instead of `.count` in views
- [ ] `pluck` / `select` when full objects aren't needed
- [ ] Pagination on index actions
- [ ] Background jobs for slow I/O
- [ ] `find_each` for batch processing
- [ ] Bullet gem in development

---

## Service object template

```ruby
module Tasks
  class Assigner
    def self.call(**args)
      new(**args).call
    end

    def initialize(task:, assignee:, assigned_by:)
      @task = task
      @assignee = assignee
      @assigned_by = assigned_by
    end

    def call
      validate!
      ActiveRecord::Base.transaction { perform_assignment }
      enqueue_notification
      @task
    end

    private

    def validate!
      raise ArgumentError, "Not a member" unless @task.project.member?(@assignee)
    end
  end
end
```

---

## Useful console commands

```ruby
# TaskFlow seeds
User.pluck(:id, :email)
Project.includes(:owner, :tasks).first

# Query log
ActiveRecord::Base.logger = Logger.new(STDOUT)

# Explain query
Task.overdue.explain

# Benchmark
require "benchmark"
Benchmark.ms { Project.all.map { |p| p.tasks.count } }
```

---

## Gems interviewers name-drop

| Gem | Purpose |
|-----|---------|
| Pundit / CanCanCan | Authorization |
| Sidekiq / Solid Queue | Background jobs |
| RSpec | Testing |
| FactoryBot | Test fixtures |
| Faker | Fake data |
| Kaminari / Pagy | Pagination |
| Bullet | N+1 detection |
| Brakeman | Security static analysis |
| strong_migrations | Safe migrations |
| Devise | Authentication |
| JSONAPI::Serializer / Alba | API serialization |

Know **what** each does; you don't need every gem memorized.

---

## One-liners for "it depends" questions

- **Service object?** "When logic involves multiple models, transactions, or side effects."
- **Callback?** "Only for simple, same-model, synchronous data normalization."
- **Concern?** "Shared behavior across models/controllers, not a junk drawer."
- **Cache?** "When read-heavy, expensive to compute, and stale data is acceptable."
- **Job?** "Anything slower than ~100ms or external I/O."

---

Print this or keep it open during TaskFlow exercises. Test yourself: cover the code column and recite the API from memory.
