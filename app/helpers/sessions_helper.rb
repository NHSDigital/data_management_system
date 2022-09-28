# This module provides helper methods for the login/logout pages
module SessionsHelper
  def primary_is_live
    # Multiple databases can be specified in certain environments, whereas in others there
    # is no choice.
    config = ActiveRecord::Base.configurations.
             configs_for(env_name: Rails.env, spec_name: 'primary').config
    primary_database = config['database']
    primary_database !~ MIGRATION_DATABASE_PATTERN
  end

  def login_message
    # A login message can be configured. If not supplied, defaults to a "this isn't live" warning,
    # unless this *is* live! Note the configuration file should be HTML-safe
    config = ActiveRecord::Base.configurations.
             configs_for(env_name: Rails.env, spec_name: 'primary').config
    login_message = config['login_message']
    unless primary_is_live
      login_message ||= "This is NOT the live system, it is the #{Rails.env.upcase} version " \
                        'of the system used for development and testing.'
    end
    login_message
  end

  # Returns the PHE logo
  # def phe_logo
  #   content_tag(:div, id: 'whitehall-wrapper') do
  #     content_tag(:div, class: 'logo') do
  #       content_tag(:h1) do
  #         image_tag('org_crest_27px_x2.png', height: 40) +
  #           content_tag(:span, 'Public Health <br>England'.html_safe)
  #       end
  #     end
  #   end
  # end

  # Return true if the user is using IE8 and they have
  # compatability mode on (so it will behave like IE7).
  def ie8_compatibility_view_on?
    agent = request.env['HTTP_USER_AGENT'].to_s
    agent.include?('MSIE 7.') && agent.include?('Trident')
  end
end
