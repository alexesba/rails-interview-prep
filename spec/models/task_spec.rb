# frozen_string_literal: true

require "rails_helper"

RSpec.describe Task, type: :model do
  describe "validations" do
    it "rejects a due date in the past on create" do
      task = build(:task, due_at: 1.day.ago)

      expect(task).not_to be_valid
      expect(task.errors[:due_at]).to be_present
    end

    it "allows a nil due date on create" do
      task = build(:task, due_at: nil)

      expect(task).to be_valid
    end

    it "allows updating a task that is already overdue" do
      task = create(:task, due_at: 1.day.ago, status: "todo")
      task.status = "in_progress"

      expect(task).to be_valid
    end
  end

  describe ".overdue" do
    it "includes past-due tasks that are not done" do
      overdue = create(:task, due_at: 1.day.ago, status: "todo")
      create(:task, due_at: 1.day.ago, status: "done")
      create(:task, due_at: 1.day.from_now, status: "todo")

      expect(described_class.overdue).to contain_exactly(overdue)
    end
  end

  describe ".by_status" do
    it "filters by status" do
      todo = create(:task, status: "todo")
      create(:task, status: "done")

      expect(described_class.by_status("todo")).to contain_exactly(todo)
    end
  end

  describe ".assigned_to" do
    it "returns tasks for the given user" do
      user = create(:user)
      assigned = create(:task, assignee: user)
      create(:task, assignee: create(:user))

      expect(described_class.assigned_to(user)).to contain_exactly(assigned)
    end
  end

  describe "#overdue?" do
    it "is true when due_at is in the past and status is not done" do
      task = build(:task, due_at: 1.hour.ago, status: "todo")

      expect(task).to be_overdue
    end
  end
end
