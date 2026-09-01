class ProjectsController < ApplicationController
  def index
    @projects = Project.all
    render json: @projects.map { |project| serialize_project(project) }
  end

  def show
    @project = Project.find(params[:id])
    render json: serialize_project(@project)
  end

  def create
    @project = Project.new(project_params.merge(owner: current_user))
    if @project.save
      render json: serialize_project(@project), status: :created
    else
      render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def project_params
    params.require(:project).permit(:name, :description, :status)
  end

  def serialize_project(project)
    {
      id: project.id,
      name: project.name,
      description: project.description,
      status: project.status,
      owner: { id: project.owner.id, name: project.owner.name },
      tasks_count: project.tasks.count,
      members: project.project_memberships.map do |membership|
        { id: membership.user.id, name: membership.user.name, role: membership.role }
      end
    }
  end
end
