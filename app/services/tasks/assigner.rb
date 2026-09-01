# frozen_string_literal: true

module Tasks
  class Assigner
    def self.call(task:, assignee:, assigned_by:)
      new(task: task, assignee: assignee, assigned_by: assigned_by).call
    end

    def initialize(task:, assignee:, assigned_by:)
      @task = task
      @assignee = assignee
      @assigned_by = assigned_by
    end

    def call
      raise NotImplementedError
    end
  end
end
