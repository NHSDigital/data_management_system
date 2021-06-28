class ApplicationMailer < ActionMailer::Base
  default from: -> { "DMS #{Mbis.stack.upcase} no-reply <admin.ecric@nhs.net>" }
  layout 'mailer'

  def self.with(params)
    params[:url_options]            ||= {}
    params[:url_options][:host]     ||= default_url_options[:host]
    params[:url_options][:port]     ||= default_url_options[:port]
    params[:url_options][:protocol] ||= default_url_options[:protocol]

    super
  end

  def url_options
    return super unless params

    params[:url_options] || super
  end
end
