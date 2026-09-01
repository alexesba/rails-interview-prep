# TaskFlow Domain

This is the **requirements document** — what you'd get in a real interview or ticket, not how to implement it.

Use `db/schema.rb`, `db/seeds.rb`, and `bin/rails routes` to explore the app. Draw the entity relationships yourself before writing code.

---

## Glossary

| Term | Meaning |
|------|---------|
| **Owner** | User who created a project (`projects.owner_id`) |
| **Member** | User linked to a project via `project_memberships` |
| **Assignee** | User responsible for a task (`tasks.assignee_id`, optional) |
| **Creator** | User who created a task (`tasks.creator_id`) |

---

## Users

- Have `name`, `email`, `password`, and `role` (`admin` or `member`).
- Can **own** multiple projects.
- Can **join** multiple projects (with a role on the membership).
- Can be **assigned** tasks on projects they belong to.
- Can **create** tasks and **comment** on tasks.

---

## Projects

- Belong to one owner.
- Have many tasks.
- Have a `status`: `active` or `archived`.
- A user should be considered a **member** if they are the owner **or** have a `project_membership` record.

---

## Project memberships

- Join table between users and projects.
- Each membership has a `role`: `owner`, `admin`, `member`, or `viewer`.
- Roles `owner`, `admin`, and `member` can manage tasks (`can_manage_tasks?`).
- When someone is added to a project, they should eventually be notified (not necessarily during the HTTP request).

---

## Tasks

- Belong to a project.
- Have `title`, `description`, `status`, `priority`, optional `due_at`.
- Statuses: `todo`, `in_progress`, `done`, `cancelled`.
- Priorities: `low`, `medium`, `high`, `urgent`.
- Have a creator (required) and optional assignee.
- Can have many tags (many-to-many via `task_tags`).
- Can have many comments.
- A task is **overdue** when it has a `due_at` in the past and is not `done`.
- New tasks should not be created with a `due_at` in the past.
- Reassigning a task should notify the new assignee (asynchronously).

---

## Comments

- Have `body` and an author.
- Currently tied to a task only — the product team wants comments on **tasks and projects** (same model, different parents).

---

## API authentication (simplified)

Requests must include `X-User-Id` with a valid user ID. No session or JWT for this exercise.

---

## Authorization rules (product)

| Action | Who |
|--------|-----|
| List/view projects | Members of the project, or system `admin` |
| Create project | Any authenticated user (becomes owner) |
| Update/delete project | Owner, project `admin` membership, or system `admin` |
| View tasks | Project members |
| Create/update tasks | Membership roles that can manage tasks |
| Delete tasks | Project owner or `admin` membership |
| Search users | Public (no auth) — must be safe |

---

## Entity relationship (intentionally blank)

Fill this in yourself after exploring the schema:

```
User ────── ?
Project ─── ?
Task ────── ?
ProjectMembership ── ?
Comment ─── ?
Tag ─────── ?
```

Check your diagram against `SOLUTIONS.md` only after Exercise 1.
