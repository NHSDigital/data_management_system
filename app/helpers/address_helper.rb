module AddressHelper
  # TODO: show historic addresses. For now objects only have one address
  def address_tag(klass)
    recent_address = klass.addresses.order('created_at desc').limit(1)
    return if recent_address.blank?

    address = recent_address.first.attributes.
              values_at('add1', 'add2', 'city', 'postcode', 'telephone')

    address << recent_address.first.country_value if recent_address.first.country
    address.compact!

    content_tag :address, safe_join(address.compact, raw('<br />'))
  end

  def most_recent_telephone_number(klass)
    recent_address = klass.addresses.order('created_at desc').limit(1)
    return if recent_address.blank?

    recent_address.first.telephone
  end
end
