class ProjectPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    raise NotImplementedError
  end

  def create?
    user.present?
  end

  def update?
    raise NotImplementedError
  end

  def destroy?
    raise NotImplementedError
  end

  class Scope < Scope
    def resolve
      raise NotImplementedError
    end
  end
end
