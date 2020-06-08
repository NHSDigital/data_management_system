class DirectoratesController < ApplicationController
  load_and_authorize_resource

  respond_to :js, :html

  def index
    @directorates = Directorate.all.order('name')
  end

  def create
    if @directorate.save
      respond_to do |format|
        format.html { redirect_to directorates, notice: message }
        format.js
      end
    else
      render :new
    end
  end

  def destroy
    return if cannot?(:destroy, @directorate)
    if @directorate.users.in_use.any? || @directorate.teams.active.any?
      redirect_to directorates_url, alert: "You can't delete directorate as it assigned to active user or active teams"
    else
      @directorate.destroy
      redirect_to directorates_url, notice: "Directorate was successfully deleted."
    end
  end

  def directorate_params
    params.require(:directorate).permit(:name, :active)
  end

end
