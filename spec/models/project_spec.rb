# frozen_string_literal: true

require "rails_helper"

RSpec.describe Project, type: :model do
  describe "members" do
    it "returns users who have a membership" do
      project = create(:project)
      member = create(:user)
      create(:project_membership, project: project, user: member)

      expect(project.members).to include(member)
    end
  end

  describe ".active" do
    it "returns only active projects" do
      active = create(:project, status: "active")
      create(:project, status: "archived")

      expect(described_class.active).to contain_exactly(active)
    end
  end

  describe ".archived" do
    it "returns only archived projects" do
      create(:project, status: "active")
      archived = create(:project, status: "archived")

      expect(described_class.archived).to contain_exactly(archived)
    end
  end

  describe ".for_user" do
    it "includes projects owned by the user" do
      user = create(:user)
      owned = create(:project, owner: user)

      expect(described_class.for_user(user)).to include(owned)
    end

    it "includes projects where the user is a member" do
      user = create(:user)
      project = create(:project)
      create(:project_membership, user: user, project: project)

      expect(described_class.for_user(user)).to include(project)
    end

    it "excludes unrelated projects" do
      user = create(:user)
      create(:project)

      expect(described_class.for_user(user)).to be_empty
    end
  end

  describe "#member?" do
    it "is true for the owner" do
      owner = create(:user)
      project = create(:project, owner: owner)

      expect(project.member?(owner)).to be true
    end

    it "is true for a user with a membership" do
      project = create(:project)
      member = create(:user)
      create(:project_membership, user: member, project: project)

      expect(project.member?(member)).to be true
    end
  end
end
