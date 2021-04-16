# helper for the Address class
module AddressHelper
  def address_tag(address)
    return if address.blank?

    address_array = address.attributes.values_at('add1', 'add2', 'city', 'postcode', 'telephone')

    address_array << address.country_value if address.country
    address_array.compact!

    content_tag :address, safe_join(address_array.compact, raw('<br />'))
  end

  def most_recent_telephone_number(klass)
    recent_address = klass.addresses.order('created_at desc').limit(1)
    return if recent_address.blank?

    recent_address.first.telephone
  end
end
