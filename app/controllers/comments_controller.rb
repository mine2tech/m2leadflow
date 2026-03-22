class CommentsController < ApplicationController
  def create
    @commentable = find_commentable
    @comment = @commentable.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      @activity = @commentable.activities.where(action: "comment_added").order(created_at: :desc).first
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: root_path, notice: "Comment added." }
      end
    else
      redirect_back fallback_location: root_path, alert: "Comment could not be saved."
    end
  end

  private

  def find_commentable
    if params[:contact_id]
      Contact.find(params[:contact_id])
    elsif params[:company_id]
      Company.find(params[:company_id])
    else
      raise ActiveRecord::RecordNotFound, "Commentable not found"
    end
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
