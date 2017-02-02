require 'pry'

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
	begin
		if count > 25
			event.respond ":x: Only up to 25 entries can be shown."
			return
		end

		text = leaderboards.take(count).map.each_with_index do |(name, tr), index|
			"#{index + 1}. **#{name}**: #{tr}"
		end.join("\n")

		event.channel.send_message '', false, Discordrb::Webhooks::Embed.new(title: "Top #{count} Jurors", description: text)

	rescue => err
		binding.pry
	end
end