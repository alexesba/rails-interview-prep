class ProjectMembership < ApplicationRecord
  ROLES = %w[owner admin member viewer].freeze

  belongs_to :user
  belongs_to :project

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :project_id }

  after_create :notify_user

  def can_manage_tasks?
    %w[owner admin member].include?(role)
  end

  private

  def notify_user
    sleep 0.01
    Rails.logger.info("[Membership] Notified #{user.email} about project #{project.name}")
  end
end
