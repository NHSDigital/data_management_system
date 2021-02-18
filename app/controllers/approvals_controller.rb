# Abstract parent class for approvals/rejections controllers
class ApprovalsController < ApplicationController
  def new
    respond_to do |format|
      format.js
    end
  end

  def create
    raise NotImplementedError
  end

  def destroy
    raise NotImplementedError
  end

  private

  def resource_params
    raise NotImplementedError
  end

  def comment_params
    return {} unless resource_params.dig(:comments_attributes, '0')

    resource_params.permit(comments_attributes: %i[body]).tap do |object|
      object[:comments_attributes]['0'][:user] = current_user
    end
  end
end
