# Adds some helpers for drawing UI controls.
module SearchHelper
  def search_text_field(form, field, value, placeholder)
    form.text_field(field, value: value, class: 'form-control', placeholder: placeholder)
  end

  def search_button(form)
    content_tag(:span, class: "input-group-btn") do
      form.button(button_options) do
        concat bootstrap_icon_tag('search')
      end
    end
  end
  
  def button_options
    {
      name: :submit,
      type: :submit,
      class: 'btn btn-primary',
      'aria-label' => 'Search',
      'data-disable' => true
    }
  end
  # <span class="input-group-btn">
  #   <%= form.button organisation: :submit, type: :submit, class: 'btn btn-primary', 'aria-label': 'Search', 'data-disable': true do %>
  #     <%= bootstrap_icon_tag('search') %>
  #   <% end %>
  # </span>
end


# <%= form_with url: teams_path, scope: :search, method: :get, id: 'search-form' do |form| %>
#   <div class="form-group">
#     <%= form.label :name, class: 'sr-only' %>
#     <div class="input-group">
#       <%= form.text_field :organisation, class: 'form-control', value: params.dig(:search, :organisation), placeholder: 'Search by organisationi...' %>
#       <span class="input-group-btn">
#         <%= form.button organisation: :submit, type: :submit, class: 'btn btn-primary', 'aria-label': 'Search', 'data-disable': true do %>
#           <%= bootstrap_icon_tag('search') %>
#         <% end %>
#       </span>
#       <%= form.text_field :name, class: 'form-control', value: params.dig(:search, :name), placeholder: 'Search by name...' %>
#       <span class="input-group-btn">
#         <%= form.button name: :submit, type: :submit, class: 'btn btn-primary', 'aria-label': 'Search', 'data-disable': true do %>
#           <%= bootstrap_icon_tag('search') %>
#         <% end %>
#       </span>
#     </div>
#   </div>
# <% end %>
