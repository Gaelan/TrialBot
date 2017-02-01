class User < ActiveRecord::Base
  validates :discord_id, presence: true, numericality: { only_integer: true, greater_than: 0 }, uniqueness: true
  validates :tos_name, presence: true, uniqueness: true

  def try_verify(key)
    correct_key = Digest::SHA1.hexdigest ENV['TOS_Bot_AUTH_SALT'] + tos_name
    if key == correct_key
      update(verified: true)
      return true
    else
      return false
    end
  end
end

class Discordrb::User
  def db_user
    User.find_by_discord_id self.id
  end
end

def authenticate(message)
  user = message.author.db_user
  if user
    if user.verified?
      yield user
    else
      message.respond ':exclamation: You still haven\'t verified your account! Go to http://blankmediagames.com/Trial/api/discord.php to verify.'
    end
  else
    message.respond ':exclamation: You need to link your Town of Salem account! Type **!ign YourToSName** to begin.'
  end
end

Bot.command :logout do |message|
  unless message.author.db_user
    message.respond ":confused: You're not even logged in!"
    return
  end
  message.author.db_user.destroy!
  message.respond ':door: Logged out!'
end