# frozen_string_literal: true

module Tasks
  class FilterQuery
    def initialize(scope:, filters:)
      @scope = scope
      @filters = filters
    end

    def call
      raise NotImplementedError
    end
  end
end
