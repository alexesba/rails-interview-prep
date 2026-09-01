# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  describe "project access" do
    it "returns projects the user belongs to via membership" do
      user = create(:user)
      membership_project = create(:project)
      create(:project_membership, user: user, project: membership_project)

      expect(user.projects).to include(membership_project)
    end

    it "does not return projects the user has no relationship with" do
      user = create(:user)
      stranger_project = create(:project)

      expect(user.projects).not_to include(stranger_project)
    end
  end

  describe "tasks" do
    it "returns tasks assigned to the user" do
      user = create(:user)
      task = create(:task, assignee: user)

      expect(user.assigned_tasks).to include(task)
    end

    it "returns tasks created by the user" do
      user = create(:user)
      task = create(:task, creator: user)

      expect(user.created_tasks).to include(task)
    end
  end

  describe "comments" do
    it "returns comments authored by the user" do
      user = create(:user)
      comment = create(:comment, author: user)

      expect(user.comments).to include(comment)
    end
  end
end
