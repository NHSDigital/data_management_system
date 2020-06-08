class ApplicationMailer < ActionMailer::Base
  default from: 'MBIS no-reply <admin.ecric@nhs.net>'
  layout 'mailer'
end
