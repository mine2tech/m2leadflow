class TaskMonitorController < ApplicationController
  def index
    @tasks = Task.order(created_at: :desc).limit(100)
    @tasks = @tasks.where(status: params[:status]) if params[:status].present?
    @tasks = @tasks.where(task_type: params[:type]) if params[:type].present?
  end

  def new
    @task = Task.new
  end

  def create
    @task = Task.new(
      task_type: params[:task][:task_type],
      user: current_user
    )

    begin
      @task.payload = JSON.parse(params[:task][:payload_json])
    rescue JSON::ParserError => e
      @task.errors.add(:base, "Invalid JSON payload: #{e.message}")
      return render :new, status: :unprocessable_entity
    end

    if @task.save
      redirect_to task_monitor_index_path, notice: "Task created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def retry_task
    task = Task.find(params[:id])
    task.update!(status: :pending, error: nil)
    redirect_to task_monitor_index_path, notice: "Task requeued."
  end
end
