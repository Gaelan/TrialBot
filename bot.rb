require 'nokogiri'
require 'open-uri'
require 'discordrb'
require 'yaml'
require 'active_support/all'
require 'active_record'
require 'pry'
require 'digest/sha1'
require 'mechanize'
require 'json'

ActiveRecord::Base.configurations = YAML.load(File.open('db/config.yml'))
ActiveRecord::Base.establish_connection

class User < ActiveRecord::Base
  validates :discord_id, presence: true, numericality: { only_integer: true, greater_than: 0 }, uniqueness: true
  validates :tos_name, presence: true, uniqueness: true

  def try_verify(key)
    correct_key = Digest::SHA1.hexdigest 'b956d835a1' + tos_name
    if key == correct_key
      update(verified: true)
      return true
    else
      return false
    end
  end
end

class Report
  attr_accessor :id
  def initialize(id)
    @id = id
  end

  def description
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

    data_text + "\n" + url
  end
end

class Discordrb::User
  def db_user
    User.find_by_discord_id self.id
  end
end

bot = Discordrb::Commands::CommandBot.new YAML.load(File.open('discord_config.yaml')).with_indifferent_access

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

def api_call(options)
  agent = Mechanize.new
  page = agent.get('http://www.blankmediagames.com/phpbb/')
  page = page.links_with(text: 'Login')[0].click
  form = page.forms[1] # first form is search form
  form.username = ENV['TOS_USERNAME']
  form.password = ENV['TOS_PASSWORD']
  page = agent.submit(form, form.buttons[0])
  JSON.parse(agent.get_file("http://blankmediagames.com/Trial/api/api.php?#{options.to_a.map { |x| x.join '=' }.join '&'}"))
end

bot.command :logout do |message|
  message.author.db_user.destroy!
  message.respond ':door: Logged out!'
end

bot.command :reports do |message|
  authenticate(message) do |user|
    reports = api_call action: 'getreports', user: user.tos_name
    message.respond ':arrow_right: Report information sent via PM.'
    if reports['ErrorMessage'] && reports['ErrorMessage'] =~ /no guilty reports/
      message.author.pm ":star2: #{reports['ErrorMessage']}"
    elsif reports['ErrorMessage'] != ''
      message.author.pm ":x: #{reports['ErrorMessage']}"
    else
      message.author.pm ":frowning: You have #{reports['ReportID'].length} guilty reports:"
      reports['ReportID'].each do |id|
        message.author.pm Report.new(id).description
      end
    end
    return
  end
end

bot.command :ign do |message, ign|
  user = User.new(discord_id: message.author.id, tos_name: ign)
  if !user.valid?
    message.respond ":x: #{user.errors.full_messages.join ', '}"
    return
  end
  user.save
  ":pencil: Copy the command from http://blankmediagames.com/Trial/api/discord.php to link your Discord account to **#{ign}**."
end

bot.command :debug do |message, command|
  if message.author.distinct == 'Gaelan#0424'
    message.respond eval(command).inspect
  end
end

bot.command :restart do |message|
  if message.author.distinct == 'Gaelan#0424'
    message.respond 'Restarting.'
    Process.spawn 'ruby bot.rb'
    exit
  end
end

bot.command :verify do |message, key|
  user = message.author.db_user
  succeeded = user.try_verify(key)
  if succeeded
    message.respond ":white_check_mark: You've been verified as **#{user.tos_name}**!"
  else
    message.respond ":x: Invalid key."
  end
end

bot.message(contains: /\A\d+\z/) do |message|
  id = message.content.to_i

  message.respond Report.new(id).description
end

bot.run
