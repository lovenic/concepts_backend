class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM_ADDRESS", "tim@conceptsapp.live")
  layout "mailer"
end
