class ApplicationMailer < ActionMailer::Base
  default from: 'DMS no-reply <admin.ecric@nhs.net>'
  layout 'mailer'
end
