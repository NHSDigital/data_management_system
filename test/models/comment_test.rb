require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  test 'belongs to a commentable' do
    comment = comments(:test_comment)

    assert_instance_of Project, comment.commentable
  end

  test 'belongs to a user' do
    comment = comments(:test_comment)

    assert_instance_of User, comment.user
  end

  test 'should require an associated commentable' do
    comment = Comment.new(
      user: users(:standard_user),
      body: 'Test'
    )

    refute comment.valid?
    assert_includes comment.errors.details[:commentable], error: :blank
  end

  test 'should require an associated user' do
    comment = Comment.new(
      commentable: projects(:dummy_project),
      body: 'Test'
    )

    refute comment.valid?
    assert_includes comment.errors.details[:user], error: :blank
  end

  test 'should be invalid without a body' do
    comment = Comment.new

    refute comment.valid?
    assert_includes comment.errors.details[:body], error: :blank
  end

  test 'should be auditable' do
    comment = comments(:test_comment)

    with_versioning do
      assert_auditable(comment)
    end
  end

  test 'should be taggable' do
    comment = Comment.new(
      commentable: projects(:dummy_project),
      user: users(:standard_user),
      body: 'Test comment'
    )

    assert_equal [], comment.tags

    comment.tags << 'TestTag'
    comment.save
    comment.reload

    assert_includes comment.tags, 'TestTag'
  end

  test 'should reject blank tags' do
    comment = comments(:test_comment)

    assert_no_changes -> { comment.reload.tags } do
      comment.tags.concat ['', nil]
      comment.save
    end
  end
end
