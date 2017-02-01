Bot.command :debug do |message, command|
  if message.author.distinct == 'Gaelan#0424'
    message.respond eval(command).inspect
  end
end

Bot.command :restart do |message|
  if message.author.distinct == 'Gaelan#0424'
    message.respond 'Restarting.'
    Process.spawn 'ruby bot.rb'
    exit
  end
end