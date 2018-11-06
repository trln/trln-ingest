class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  def username
    @username ||= email.gsub(/@.*/, '')
  end

  def active_for_authentication?
    super && approved?
  end

  acts_as_token_authenticatable

  def inactive_message
    if !approved?
      :not_approved
    else
      super
    end
  end
end
