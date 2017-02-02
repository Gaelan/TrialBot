require_relative 'accounts'

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

Bot.command :toptr do |event, count = 10|
	event.channel.start_typing
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
		rank = board.find_index { |name, _| name == user.tos_name } + 1
		unless rank
			event.respond ":stuck_out_tongue: You're not even on the leaderboard."
			return
		end
		event.respond "**#{user.tos_name}** is in **#{rank.ordinalize}** place with a Trial Rank of **#{board[user.tos_name]}**"
	end
end