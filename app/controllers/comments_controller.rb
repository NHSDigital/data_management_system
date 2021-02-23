# RESTfully manages `Comment`s
class CommentsController < ApplicationController
  load_and_authorize_resource through: :commentable, shallow: true, only: %i[create destroy]

  def index
    @comments = commentable.comments.includes(:user).order(created_at: :desc)
    @comment  = Comment.new(commentable: commentable)

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
    params.require(:comment).permit(:body)
  end

  def commentable
    @commentable ||= begin
      param_key, id = request.path_parameters.detect { |key, _| key.to_s =~ /\A\w+_id\z/ }

      if param_key
        klass = (params[:commentable_class] || param_key.to_s.gsub('_id', '')).
                classify.
                constantize

        klass.find(id).tap { |object| authorize!(:read, object) }
      end
    end
  end
end
