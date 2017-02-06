require_relative 'accounts'

INFO_FIELDS = {
	meritpoints: {name: 'Merit Points', emoji: 'dollar', hide: true},
	townpoints: {name: 'Town Points', emoji: 'dollar', hide: true},
	casualwinloss: {name: 'Casual Win Rate', emoji: 'video_game', format: :percent},
	rankedwinloss: {name: 'Ranked Win Rate', emoji: 'first_place', format: :percent},
	elo: {name: 'Elo', emoji: 'first_place'}
}

def format(value, format)
	case format
	when :percent
		'%.1f%%' % (value.to_f * 100)
	else
		value
	end
end


INFO_FIELDS.each do |name, info|
	Bot.command name do |event|
		event.channel.start_typing
		authenticate(event) do |user|
			response = api_call action: 'info', user: user.tos_name
			value = format(response[name.to_s], info[:format])
			event.respond ":#{info[:emoji]}: **#{user.tos_name}**'s #{info[:name]} is **#{value}**"
		end
	end
end

Bot.command :info do |event|
	event.channel.start_typing
	authenticate(event) do |user|
		response = api_call action: 'info', user: user.tos_name
		embed = create_embed title: user.tos_name
		INFO_FIELDS.each do |name, field|
			next if field[:hide]
			embed.add_field name: field[:name], value: format(response[name.to_s], field[:format]), inline: true
		end
		event.channel.send_message '', false, embed
	end
end

Bot.command :top10 do |event|
	event.channel.start_typing
	response = api_call action: 'top10'

	emojis = %w(first_place second_place third_place four five six seven eight nine keycap_ten)

	strings = response['userlist'].map.each_with_index do |name, idx|
		"#{idx + 1}. **#{name}**, with **#{response['elolist'][idx]}** elo"
	end
	event.channel.send_message '', false, create_embed(title: 'Top 10 Elo', description: strings.join("\n\n"))
	nil
end