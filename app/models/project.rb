class Project < ApplicationRecord
  STATUSES = %w[active archived].freeze

  belongs_to :owner, class_name: "User"
  has_many :tasks, dependent: :destroy

  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }

  def member?(user)
    owner_id == user.id || project_memberships.exists?(user: user)
  end
end
