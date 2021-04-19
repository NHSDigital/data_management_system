# Controlller for Addresses
class AddressesController < ApplicationController
  def default_address
    address = Address.find(params[:default_address_id])
    address_owner = address.addressable
    Address.transaction do
      address_owner.addresses.update_all(default_address: false)
      address.update(default_address: true)
      redirect_to address_owner, notice: 'Default address updated'
    end
  end
end
