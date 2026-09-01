class TasksController < ApplicationController
  before_action :set_project

  def index
    tasks = @project.tasks

    tasks = tasks.where(status: params[:status]) if params[:status].present?
    tasks = tasks.where(assignee_id: params[:assignee_id]) if params[:assignee_id].present?

    render json: tasks.map { |task| serialize_task(task) }
  end

  def create
    @task = @project.tasks.new(task_params.merge(creator: current_user))

    if @task.save
      render json: serialize_task(@task), status: :created
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def assign
    @task = @project.tasks.find(params[:id])
    @task.update!(assignee_id: params[:assignee_id])
    render json: serialize_task(@task)
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :status, :priority, :due_at, :assignee_id)
  end

  def serialize_task(task)
    {
      id: task.id,
      title: task.title,
      status: task.status,
      priority: task.priority,
      due_at: task.due_at,
      assignee: task.assignee ? { id: task.assignee.id, name: task.assignee.name } : nil,
      tags: task.tags.map(&:name),
      comments_count: task.comments.count
    }
  end
end
