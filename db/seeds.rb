# frozen_string_literal: true

admin = User.find_or_create_by!(email: "admin@example.com") do |user|
  user.name = "Admin User"
  user.password = "password123"
  user.role = "admin"
end

alice = User.find_or_create_by!(email: "alice@example.com") do |user|
  user.name = "Alice"
  user.password = "password123"
end

bob = User.find_or_create_by!(email: "bob@example.com") do |user|
  user.name = "Bob"
  user.password = "password123"
end

project = Project.find_or_create_by!(name: "Interview Prep App", owner: alice) do |p|
  p.description = "Practice project for Rails mid/senior interviews"
  p.status = "active"
end

ProjectMembership.find_or_create_by!(user: alice, project: project) { |m| m.role = "owner" }
ProjectMembership.find_or_create_by!(user: bob, project: project) { |m| m.role = "member" }

%w[bug feature refactor docs].each do |tag_name|
  Tag.find_or_create_by!(name: tag_name)
end

task = Task.find_or_create_by!(project: project, title: "Fix N+1 in projects#index") do |t|
  t.description = "Eager load associations to avoid N+1 queries"
  t.status = "in_progress"
  t.priority = :high
  t.creator = alice
  t.assignee = bob
  t.due_at = 3.days.from_now
end

task.tags << Tag.find_by!(name: "bug") unless task.tags.exists?(name: "bug")

Comment.find_or_create_by!(task: task, author: bob) do |c|
  c.body = "I think we need includes(:owner, :project_memberships => :user)"
end

puts "Seeded users (use X-User-Id header):"
puts "  Admin: #{admin.id} (#{admin.email})"
puts "  Alice: #{alice.id} (#{alice.email})"
puts "  Bob:   #{bob.id} (#{bob.email})"
puts "Project: #{project.id} - #{project.name}"
