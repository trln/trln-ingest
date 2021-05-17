class AuthorityMailer < ApplicationMailer
  default from: 'admin@trln.org'

  def notify_lcnaf(user, attachment)
  	attachments["lcnaf-#{Time.current.to_date.strftime('%F')}.txt"] = attachemnt
    mail(to: user.email, 
    	subject: 'Authority Records update status', 
    	body: 'Open an attachemnt to see the status of the util:lcnaf:rebuild task.').deliver
  end
end
