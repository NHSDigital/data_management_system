# Controller for Organisation
class OrganisationsController < ApplicationController
  load_and_authorize_resource

  respond_to :js, :html

  def index
    @organisations = @organisations.search(search_params).paginate(page: params[:page], per_page: 15)
  end

  def show
    @teams = @organisation.teams.search(@organisation.teams, search_params).
             paginate(page: params[:page], per_page: 15)
  end

  def new; end

  def edit; end

  def create
    if @organisation.save
      redirect_to @organisation, notice: 'Organisation was successfully created.'
    else
      render :new
    end
  end

  def update
    if @organisation.update(resource_params)
      redirect_to @organisation, notice: 'Organisation was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    if @organisation.destroy
      redirect_to organisations_url, notice: 'Organisation was successfully destroyed.'
    else
      redirect_to @organisation, notice: 'Could not destroy organisation!'
    end
  end

  private

  def resource_params
    params.require(:organisation).permit(
      :name,
      :organisation_type_id,
      :organisation_type_other,
      addresses_attributes: %i[id add1 add2 postcode telephone
                               country_id city telephone _destroy]
    )
  end

  def search_params
    params.fetch(:search, {}).permit(:name, :organisation)
  end
end
