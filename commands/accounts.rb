class User < ActiveRecord::Base
  validates :discord_id, presence: true, numericality: { only_integer: true, greater_than: 0 }, uniqueness: true
  validates :tos_name, presence: true, uniqueness: true

  def try_verify(key)
    correct_key = Digest::SHA1.hexdigest ENV['TOS_BOT_AUTH_SALT'] + tos_name
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

Bot.command :ign do |message, ign|
  user = User.new(discord_id: message.author.id, tos_name: ign)
  if !user.valid?
    message.respond ":x: #{user.errors.full_messages.join ', '}"
    return
  end
  user.save
  ":pencil: Copy the command from http://blankmediagames.com/Trial/api/discord.php to link your Discord account to **#{ign}**."
end

Bot.command :logout do |message|
  unless message.author.db_user
    message.respond ":confused: You're not even logged in!"
    return
  end
  message.author.db_user.destroy!
  message.respond ':door: Logged out!'
end

Bot.command :verify do |message, key|
  user = message.author.db_user
  unless user
    message.respond ":confused: Type !ign <your name> first."
    return
  end
  succeeded = user.try_verify(key)
  if succeeded
    message.respond ":white_check_mark: You've been verified as **#{user.tos_name}**!"
  else
    message.respond ":x: Invalid key."
  end
end

Bot.command :getign do |message, player|
  unless player =~ /<@(\d+)>/
    message.respond ":x: Syntax: !getign @PlayerName#1234"
    return
  end

  account = User.find_by_discord_id($1)

  unless account
    message.respond ":x: <@#{player}> isn't linked to Discord."
    return
  end

  message.respond "#{player} is **#{account.tos_name}** on ToS."
end
