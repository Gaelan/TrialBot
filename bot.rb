require 'nokogiri'
require 'open-uri'
require 'discordrb'
require 'yaml'

bot = Discordrb::Bot.new YAML.load(File.load('config.yaml'))

bot.message(contains: /\A\d+\z/) do |message|
  id = message.content.to_i
  url = "http://www.blankmediagames.com/Trial/viewReport.php?id=#{id}"
  doc = Nokogiri::HTML(open(url))

  data = {
    'Report ID' => :reportId,
    'Reported Player' => :reportedPlayer,
    'Reported Reason' => :reportReason,
    'Details' => :reportDescription,
  }

  data_text = data.map do |key, raw_value|
    value = doc.at_css('.' + raw_value.to_s).text
    "**#{key}:** #{value}"
  end.join("\n")

  message.respond data_text + "\n" + url
end

bot.run
