class ChannelConfig < ActiveRecord::Base
	validates :channel_id, presence: true, numericality: { only_integer: true, greater_than: 0 }, uniqueness: true

	FIELDS = %i(short_reports tr_update)
end

class Discordrb::Channel
	def config
		ChannelConfig.find_or_create_by!(channel_id: id)
	end
end

Bot.command :config, required_permissions: [:manage_messages] do |event, name = nil, value = nil|
	case true
	when !name # list fields
		event << "Settings for ##{event.channel.name}:"
		ChannelConfig::FIELDS.each do |field|
			next if field == :channel_id
			event << "**#{field}**: #{event.channel.config[field]}"
		end
	when !value # get field
		return unless ChannelConfig::FIELDS.include? name.to_sym
		event << "**##{event.channel.name}.#{name}:** #{event.channel.config[name]}"
	else
		return unless ChannelConfig::FIELDS.include? name.to_sym
		config = event.channel.config
		config[name] = value
		unless config.valid?
			event << ":x: #{user.errors.full_messages.join ', '}"
		end
		config.save
		event << ":white_check_mark: ##{event.channel.name}.#{name} set to **#{config[name].inspect}**"
	end
	nil
end