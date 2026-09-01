class Task < ApplicationRecord
  STATUSES = %w[todo in_progress done cancelled].freeze
  PRIORITIES = { low: 0, medium: 1, high: 2, urgent: 3 }.freeze

  belongs_to :project
  belongs_to :assignee, class_name: "User", optional: true
  belongs_to :creator, class_name: "User"
  has_many :task_tags, dependent: :destroy
  has_many :tags, through: :task_tags
  has_many :comments, dependent: :destroy

  enum :priority, PRIORITIES, validate: true

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }

  after_update :notify_assignee_on_change

  def overdue?
    due_at.present? && due_at < Time.current && status != "done"
  end

  private

  def notify_assignee_on_change
    return unless saved_change_to_assignee_id? && assignee.present?

    sleep 0.01
    Rails.logger.info("[Task] Notified #{assignee.email} about assignment: #{title}")
  end
end
