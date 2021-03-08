# RESTfully manages `Comment`s
class CommentsController < ApplicationController
  load_and_authorize_resource through: :commentable, shallow: true, only: %i[create destroy]

  def index
    @comments = commentable.comments.includes(:user).order(created_at: :desc)
    @comment  = Comment.new(commentable: commentable)

    if tags ||= params[:tags]
      @comments = @comments.tagged_with(*tags)
      @comment.tags.concat(tags)
    end

    locals = {
      comments: @comments,
      comment:  @comments
    }

    respond_to do |format|
      format.html { render partial: 'comments', locals: locals, content_type: :html }
      format.js
    end
  end

  def create
    @comment.save

    respond_to do |format|
      format.js
    end
  end

  def destroy
    if @comment.destroy

      respond_to do |format|
        format.js
      end
    else
      respond_to do |format|
        format.js { head :unprocessable_entity }
      end
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:body, tags: [])
  end

  def commentable
    @commentable ||= begin
      path_components   = request.path.split('/')[1..-2]
      commentable_id    = path_components.pop
      commentable_class = path_components.join('/').classify.constantize

      commentable_class.find(commentable_id).tap { |object| authorize!(:read, object) }
    end
  end
end
