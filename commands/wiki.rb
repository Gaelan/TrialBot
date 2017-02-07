# This is generic, and probably should move into a seperate bot at some point.
require 'paper_trail'

class WikiEntry < ActiveRecord::Base
	has_paper_trail
end

Bot.command :wiki do |event, name = nil|
	if(!name)
		list = WikiEntry.where(server_id: event.channel.server.id).order(:name).pluck(:name).join(', ')
		event.respond ":file_cabinet: Available wiki entries: #{list}"
	else
		event.respond WikiEntry.find_by(server_id: event.channel.server.id, name: name).text
	end
end

Bot.command :wedit do |event, name = nil|
	entry = WikiEntry.find_or_initialize_by(server_id: event.channel.server.id, name: name)
	event.respond ":pencil: Your next message will be saved as **#{name}**."
	if entry.id
		event.respond "Here's the current text in case you want to copy it:"
		event.respond entry.text
	end
	event.message.await(Random.rand.to_s) do |contents_event|
		PaperTrail.whodunnit = contents_event.author.distinct
		entry.text = contents_event.text
		entry.save
		contents_event.respond ":floppy_disk: Wiki entry saved!"
	end
	nil
end

Bot.command :whistory do |event, name = nil|
	entry = WikiEntry.find_by_name(name)
	event << ":calendar_spiral: History of #{name}:"
	entry.versions.each_with_index do |v, idx|
		if idx == entry.versions.count - 1
			event << "Current Version: #{v.event} by #{v.whodunnit}"
		else
			event << "Version #{idx + 1}: #{v.event} by #{v.whodunnit}"
		end
	end
	event << "Use !wrevert #{name} [number] to revert."
	nil
end

Bot.command :wrevert do |event, name, version|
	entry = WikiEntry.find_by_name(name)
	v = entry.versions[version.to_i]
	PaperTrail.whodunnit = "#{event.author.distinct} (reverting to version #{version})"
	v.reify.save
	event << ":back: Reverted **#{name}** to version #{version}!"
end
