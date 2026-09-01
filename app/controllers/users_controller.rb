class UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:search]

  def search
    query = params[:q]
    @users = User.where("name LIKE '%#{query}%' OR email LIKE '%#{query}%'")
    render json: @users.select(:id, :name, :email)
  end
end
