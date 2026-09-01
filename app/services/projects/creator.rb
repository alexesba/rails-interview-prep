# frozen_string_literal: true

module Projects
  class Creator
    def self.call(owner:, attributes:)
      new(owner: owner, attributes: attributes).call
    end

    def initialize(owner:, attributes:)
      @owner = owner
      @attributes = attributes
    end

    def call
      raise NotImplementedError
    end
  end
end
