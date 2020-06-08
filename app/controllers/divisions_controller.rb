class DivisionsController < ApplicationController
  load_and_authorize_resource

  respond_to :js, :html

  def new
    @division = Division.new(directorate_id: params[:directorate_id])
  end

  def create
    if @division.save
      respond_to do |format|
        format.html { redirect_to directorates, notice: message }
        format.js
      end
    else
      render :new
    end
  end

  def destroy
    return if cannot?(:destroy, @division)
    @division.destroy
    redirect_to directorates_url, notice: "Division was successfully deleted."
  end

  def update
    if @division.update(division_params)
      respond_to do |format|
        format.html { redirect_to directorates_path, notice: 'User was successfully updated.' }
        format.js
      end
    else
      render :edit
    end
  end


  def division_params
    params.require(:division).permit(:name, :head_of_profession, :directorate_id, :active)
  end

end
