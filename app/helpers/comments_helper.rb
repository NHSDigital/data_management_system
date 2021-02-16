# -
module CommentsHelper
  def comments_count_badge_for(commentable, count = 0)
    tag.span(count, class: 'badge', id: "#{dom_id(commentable)}_comments_count_badge")
  end
end
