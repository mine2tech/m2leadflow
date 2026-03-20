class TaskMonitorController < ApplicationController
  def index
    @tasks = Task.order(created_at: :desc).limit(100)
    @tasks = @tasks.where(status: params[:status]) if params[:status].present?
    @tasks = @tasks.where(task_type: params[:type]) if params[:type].present?
  end

  def retry_task
    task = Task.find(params[:id])
    task.update!(status: :pending, error: nil)
    redirect_to task_monitor_index_path, notice: "Task requeued."
  end
end
