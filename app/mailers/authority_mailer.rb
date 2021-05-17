class AuthorityMailer < ApplicationMailer
  default from: ENV['ADMIN_EMAIL']

  def notify_lcnaf
    mail(to: ENV['ADMIN_EMAIL'],
      subject: 'Authority Records rebuild task status', 
      body: 'Completed adding LCNAF variant names to Redis.').deliver
  end
end
