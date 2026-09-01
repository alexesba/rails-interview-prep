# Solutions (spoiler alert)

Only read this **after** attempting each exercise. The **source of truth** for what to build is the failing specs in `spec/` and the acceptance criteria in `EXERCISES.md` — not comments in the codebase.

---

## Exercise 1 — Active Record

### User associations

```ruby
has_many :project_memberships, dependent: :destroy
has_many :projects, through: :project_memberships
has_many :assigned_tasks, class_name: "Task", foreign_key: :assignee_id
has_many :created_tasks, class_name: "Task", foreign_key: :creator_id
has_many :comments, foreign_key: :author_id
```

### Project

```ruby
has_many :project_memberships, dependent: :destroy
has_many :members, through: :project_memberships, source: :user

scope :active, -> { where(status: "active") }
scope :archived, -> { where(status: "archived") }
scope :for_user, ->(user) {
  left_joins(:project_memberships)
    .where(owner_id: user.id)
    .or(where(project_memberships: { user_id: user.id }))
    .distinct
}
```

### Task scopes

```ruby
scope :overdue, -> { where("due_at < ?", Time.current).where.not(status: "done") }
scope :by_status, ->(status) { where(status: status) }
scope :assigned_to, ->(user) { where(assignee: user) }

validate :due_at_in_future, on: :create

def due_at_in_future
  return if due_at.blank?
  errors.add(:due_at, "must be in the future") if due_at <= Time.current
end
```

---

## Exercise 2 — N+1 & Performance

### Controller eager loading

```ruby
# ProjectsController#index
@projects = policy_scope(Project)
  .includes(:owner, project_memberships: :user)
  .page(params[:page])

# Use project.tasks_count instead of project.tasks.count
# TasksController#index
tasks = Tasks::FilterQuery.new(scope: @project.tasks, filters: params).call
  .includes(:assignee, :tags)
```

### Counter cache migration

```ruby
add_column :projects, :tasks_count, :integer, default: 0, null: false
# Then: Task.reset_counters(project.id, :tasks) or rake task
```

```ruby
# Task model
belongs_to :project, counter_cache: true
```

### Indexes migration

```ruby
add_index :tasks, :status
add_index :tasks, :assignee_id
add_index :tasks, :due_at
```

---

## Exercise 3 — Service Objects

### Projects::Creator (example)

```ruby
module Projects
  class Creator
    Result = Struct.new(:success?, :project, :errors, keyword_init: true)

    def self.call(owner:, attributes:)
      new(owner: owner, attributes: attributes).call
    end

    def initialize(owner:, attributes:)
      @owner = owner
      @attributes = attributes
    end

    def call
      project = nil
      ActiveRecord::Base.transaction do
        project = Project.create!(@attributes.merge(owner: @owner))
        ProjectMembership.create!(project: project, user: @owner, role: "owner")
      end
      Result.new(success?: true, project: project, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, project: nil, errors: e.record.errors.full_messages)
    end
  end
end
```

### Tasks::Assigner (key logic)

```ruby
def call
  raise ArgumentError, "Assignee is not a project member" unless project.member?(@assignee)

  ActiveRecord::Base.transaction do
    @task.update!(assignee: @assignee)
  end

  Tasks::AssignmentNotificationJob.perform_later(
    task_id: @task.id,
    assignee_id: @assignee.id
  )

  @task
end
```

---

## Exercise 4 — REST API

- `update`: `authorize @project`; return 200 with JSON or 422 with errors.
- `destroy`: `authorize @project`; `head :no_content` on success.
- Pagination: `@projects.page(params[:page]).per(params[:per_page] || 20)`.

---

## Exercise 5 — Pundit

```ruby
class ProjectPolicy < ApplicationPolicy
  def show?
    admin? || record.member?(user)
  end

  def update?
    admin? || record.owner_id == user.id || membership&.role.in?(%w[owner admin])
  end

  def destroy?
    admin? || record.owner_id == user.id
  end

  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      scope.for_user(user)
    end
  end

  private

  def admin?
    user.admin?
  end

  def membership
    record.project_memberships.find_by(user: user)
  end
end
```

---

## Exercise 6 — Background Job

```ruby
class Tasks::AssignmentNotificationJob < ApplicationJob
  queue_as :default

  def perform(task_id:, assignee_id:)
    task = Task.find_by(id: task_id)
    return unless task
    return unless task.assignee_id == assignee_id

    Rails.logger.info("[Job] Notified user #{assignee_id} about task #{task_id}")
  end
end
```

---

## Exercise 7 — Testing

Key examples to include:

```ruby
# task_spec.rb
it { is_expected.to validate_presence_of(:title) }

describe ".overdue" do
  it "returns tasks past due date that are not done" do
    overdue = create(:task, due_at: 1.day.ago, status: "todo")
    create(:task, due_at: 1.day.ago, status: "done")
    expect(Task.overdue).to eq([overdue])
  end
end

# request spec
it "returns 401 without auth header" do
  get projects_path
  expect(response).to have_http_status(:unauthorized)
end
```

---

## Exercise 8 — Security

```ruby
# UsersController#search — SAFE
def search
  query = "%#{User.sanitize_sql_like(params[:q].to_s)}%"
  @users = User.where("name LIKE ? OR email LIKE ?", query, query)
  render json: @users.select(:id, :name, :email)
end
```

Or simply: `User.where("name LIKE :q OR email LIKE :q", q: "%#{params[:q]}%")`

---

## Exercise 9 — FilterQuery & Polymorphic Comments

### FilterQuery sketch

```ruby
def call
  scope = @scope
  scope = scope.by_status(@filters[:status]) if @filters[:status].present?
  scope = scope.assigned_to(User.find(@filters[:assignee_id])) if @filters[:assignee_id].present?
  scope = scope.overdue if ActiveModel::Type::Boolean.new.cast(@filters[:overdue])
  scope = scope.joins(:tags).where(tags: { name: @filters[:tag] }) if @filters[:tag].present?
  scope = scope.where(priority: @filters[:priority]) if @filters[:priority].present?

  case @filters[:sort]
  when "due_at" then scope.order(due_at: :asc)
  when "priority" then scope.order(priority: :desc)
  else scope.order(created_at: :desc)
  end
end
```

### Polymorphic migration

```ruby
add_reference :comments, :commentable, polymorphic: true, null: false
# migrate task_id -> commentable, remove task_id
```

```ruby
class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
end

class Task < ApplicationRecord
  has_many :comments, as: :commentable
end
```

---

## Exercise 10 — Remove callbacks

- Delete `after_update :notify_assignee_on_change` from Task.
- Delete `after_create :notify_user` from ProjectMembership.
- Call jobs explicitly from services only.
- Short ADR: callbacks hide control flow, make testing hard, and block the request thread.

---

## Bonus topics interviewers love

- **Caching:** `Rails.cache.fetch("project/#{id}/summary", expires_in: 5.minutes) { ... }`
- **Read replica:** `ActiveRecord::Base.connected_to(role: :reading) { ... }`
- **Race conditions:** use `with_lock` or unique DB constraints
- **Soft delete pitfalls:** default_scope breaks `unscoped` expectations
