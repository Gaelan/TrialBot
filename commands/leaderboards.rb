require_relative 'accounts'
require_relative 'config'

def leaderboards
	doc = Nokogiri::HTML(open('http://www.blankmediagames.com/Trial/fetch.php?from=leaderboards.php'))
	entries = doc.at_css('body').children.map &:text
	pairs = entries.map do |string|
		string.gsub! /\d+\. /, ''
		string.split ': '
	end
	pairs.select! { |pair| pair.length == 2}
	Hash[pairs]
end

Bot.command :toptr do |event, count_in = 10|
	event.channel.start_typing
	count = count_in.to_i
	if count > 25
		event.respond ":x: Only up to 25 entries can be shown."
		return
	end

	text = leaderboards.take(count).map.each_with_index do |(name, tr), index|
		"#{index + 1}. **#{name}**: #{tr}"
	end.join("\n")

	event.channel.send_message '', false, Discordrb::Webhooks::Embed.new(title: "Top #{count} Jurors", description: text)
end

Bot.command :tr do |event|
	event.channel.start_typing
	authenticate event do |user|
		board = leaderboards
		rank = board.find_index { |name, _| name == user.tos_name }&.+ 1
		unless rank
			tr = api_call(action: :trialrating, user: user.tos_name)['trialrating']
			event.respond "**#{user.tos_name}**, you have a Trial rating of **#{tr}**, but aren't on the leaderboard."
			return
		end
		event.respond "**#{user.tos_name}**, you are in **#{rank.ordinalize}** place with a Trial Rank of **#{board[user.tos_name]}**"
	end
end

def find_diff(old_array, new_array)
	old_head, *old_rest = old_array
	new_head, *new_rest = new_array
	if old_head != new_head
		[old_head, new_head]
	else
		find_diff old_rest, new_rest
	end
end

def discordify(tos_name)
	user = User.find_by_tos_name(tos_name)
	if user
		"<@#{user.discord_id}>"
	else
		"**#{tos_name}**"
	end
end

Thread.new do
	old = {"AllDaysPass"=>"2217", "Kilza"=>"1438", "jaydeamali"=>"1364", "Beyrone"=>"1088", "LiamNoOni"=>"973", "oliebollen"=>"807", "Annmunition"=>"756", "lp0onfire"=>"646", "tacticianjack"=>"617", "angeemanangee"=>"586", "wesamosi"=>"552", "Ralozey"=>"489", "Virushexe"=>"479", "wtfyote"=>"410", "WittyRecluse"=>"364", "Aurumess"=>"345", "Shakira123"=>"337", "ElBrutus"=>"314", "DoodleFungus"=>"313", "Talon1165"=>"307", "Hellpest"=>"284", "Decent60"=>"283", "DragonSaviour"=>"270", "tescao"=>"264", "Nekojin"=>"259"}
	loop do
		new = leaderboards
		puts "Running tr update. Old and new:"
		p old
		p new
		if old.keys != new.keys
			puts "Found diff."
			passed, passer = find_diff old.keys, new.keys
			ChannelConfig.where(tr_update: true).find_each do |config|
				Bot.channel(config.channel_id).send_message ":trophy: #{discordify(passer)} has passed #{discordify(passed)} on the TR leaderboard!"
			end
		end
		old = new
		sleep 10.minutes
	end
end