class UserMailer < ApplicationMailer
  def welcome_email(user)
    @user = user
    mail(
      to: @user.email,
      subject: 'Welcome to Concepts!'
    )
  end

  def account_deletion_email(user)
    @user = user
    @email = user.email
    mail(
      to: @email,
      subject: 'Your account has been deleted'
    )
  end
end
