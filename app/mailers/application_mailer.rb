class ApplicationMailer < ActionMailer::Base
  default from: -> { "DMS #{Mbis.stack.upcase} no-reply <admin.ecric@nhs.net>" }
  layout 'mailer'
end
