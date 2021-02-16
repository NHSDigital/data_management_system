require 'test_helper'

# Tests behavior of the `Commentable` concern.
class CommentableTest < ActiveSupport::TestCase
  def setup
    @commentable = projects(:dummy_project)
  end

  test 'should have many comments' do
    assert @commentable.comments.first.is_a? Comment
  end

  test 'should accept nested attributes for comments' do
    assert_difference -> { @commentable.comments.count } do
      @commentable.update(
        comments_attributes: [
          { user: users(:standard_user), body: 'RAWR!' }
        ]
      )
    end
  end

  test 'should reject nested attributes for invalid comments' do
    assert_no_difference -> { @commentable.comments.count } do
      @commentable.update(
        comments_attributes: [
          { user: users(:standard_user), body: '' }
        ]
      )
    end
  end
end
