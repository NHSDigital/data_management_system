# Logic for resources that may be commented upon.
module Commentable
  extend ActiveSupport::Concern

  included do
    has_many :comments, as: :commentable, dependent: :destroy

    accepts_nested_attributes_for :comments, reject_if: :reject_comment?
  end

  private

  def reject_comment?(attributes)
    return true if attributes[:body].blank?
    return true unless attributes.key?(:user) || attributes.key?(:user_id)
    return true if attributes.key?(:user) && attributes[:user].blank?
    return true if attributes.key?(:user_id) && attributes[:user_id].blank?

    false
  end
end
