class Tasks::AssignmentNotificationJob < ApplicationJob
  queue_as :default

  def perform(task_id:, assignee_id:)
    raise NotImplementedError
  end
end
