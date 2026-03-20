module Api
  class TasksController < BaseController
    before_action :find_task, only: [:claim, :start, :complete, :fail_task]

    # GET /api/tasks/next
    def next_task
      task = Task.next_pending.first
      if task
        render json: task_json(task)
      else
        render json: { message: "No pending tasks" }, status: :no_content
      end
    end

    # POST /api/tasks/:id/claim
    def claim
      unless @task.pending?
        return render json: { error: "Task is not pending (current: #{@task.status})" }, status: :unprocessable_entity
      end
      @task.claim!
      render json: task_json(@task)
    end

    # POST /api/tasks/:id/start
    def start
      unless @task.claimed?
        return render json: { error: "Task is not claimed (current: #{@task.status})" }, status: :unprocessable_entity
      end
      @task.start!
      render json: task_json(@task)
    end

    # POST /api/tasks/:id/complete
    def complete
      unless @task.in_progress?
        return render json: { error: "Task is not in_progress (current: #{@task.status})" }, status: :unprocessable_entity
      end

      ActiveRecord::Base.transaction do
        @task.complete!(params[:result]&.to_unsafe_h || {})
        process_task_result(@task)
      end

      render json: task_json(@task)
    rescue ActiveRecord::RecordNotFound => e
      @task.update!(status: :failed, error: "Processing failed: #{e.message}")
      render json: { error: "Task completed but processing failed: #{e.message}" }, status: :unprocessable_entity
    rescue ActiveRecord::RecordInvalid => e
      @task.update!(status: :failed, error: "Processing failed: #{e.message}")
      render json: { error: "Task completed but processing failed: #{e.message}" }, status: :unprocessable_entity
    end

    # POST /api/tasks/:id/fail
    def fail_task
      unless @task.in_progress?
        return render json: { error: "Task is not in_progress" }, status: :unprocessable_entity
      end
      @task.fail!(params[:error] || "Unknown error")
      render json: task_json(@task)
    end

    private

    def find_task
      @task = Task.find(params[:id])
    end

    def task_json(task)
      {
        id: task.id,
        task_type: task.task_type,
        payload: task.payload,
        status: task.status,
        attempts: task.attempts,
        max_attempts: task.max_attempts,
        result: task.result,
        error: task.error,
        created_at: task.created_at,
        updated_at: task.updated_at
      }
    end

    def process_task_result(task)
      case task.task_type
      when "enrich_company"
        TaskResultProcessors::EnrichCompany.call(task)
      when "draft_email"
        TaskResultProcessors::DraftEmail.call(task)
      end
    end
  end
end
