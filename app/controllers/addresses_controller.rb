# RESTfully manages Addresses
class AddressesController < ApplicationController
  def default_address
    klass = [Team, Organisation].find do |k|
      k.name == params[:addressable_type]
    end
    raise 'Addressable_type is invalid' if klass.nil?

    address_owner = klass.find(params[:addressable_id])
    address_owner.addresses.update_all(default_address: false)
    address_owner.addresses.find(params[:default_address]).update(default_address: true)
    redirect_to address_owner, notice: 'Default address updated'
  end
end
