class ApplicationController < ActionController::API
  include Pundit::Authorization

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
  rescue_from Pundit::NotAuthorizedError, with: :forbidden

  before_action :authenticate_user!

  private

  def current_user
    @current_user ||= User.find_by(id: request.headers["X-User-Id"])
  end

  def authenticate_user!
    return if current_user

    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end

  def unprocessable_entity(exception)
    render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
  end

  def forbidden
    render json: { error: "Forbidden" }, status: :forbidden
  end
end
