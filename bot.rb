require 'nokogiri'
require 'open-uri'
require 'discordrb'
require 'yaml'
require 'active_support/all'
require 'active_record'
require 'digest/sha1'
require 'mechanize'
require 'json'

ActiveRecord::Base.configurations = YAML.load(File.open('config/database.yml'))
ActiveRecord::Base.establish_connection

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

class Report
  include Discordrb
  attr_accessor :id
  def initialize(id)
    @id = id
  end

  def description
    data = {
      'Report ID' => :reportId,
      'Reported Player' => :reportedPlayer,
      'Reported Reason' => :reportReason,
      'Details' => :reportDescription,
    }

    data_text = data.map do |key, raw_value|
      value = field(raw_value)
      "**#{key}:** #{value}"
    end.join("\n")

    data_text + "\n" + url
  end

  def url
    "http://www.blankmediagames.com/Trial/viewReport.php?id=#{id}"
  end

  def doc
    @doc ||= Nokogiri::HTML(open(url))
  end

  def field(field_class)
    doc.at_css('.' + field_class.to_s).text
  end

  def status
    if doc.at_css('#splash.guilty')
      :guilty
    elsif doc.at_css('#splash.neutral')
      :no_judgement
    elsif doc.at_css('#splash.innocent')
      :innocent
    else
      :pending
    end
  end

  def embed
    Webhooks::Embed.new(
      title: "Report \##{field(:reportId)}",
      url: url,
      fields: [
        Webhooks::EmbedField.new(name: 'Reported Player', value: field(:reportedPlayer), inline: true),
        Webhooks::EmbedField.new(name: 'Reported Reason', value: field(:reportReason), inline: true),
        Webhooks::EmbedField.new(name: 'Status', value: status.to_s.humanize, inline: true)
        #Webhooks::EmbedField.new(name: 'Details', value: )
      ],
      description: field(:reportDescription),
      color: {
        guilty: 0xFF0000,
        no_judgement: 0x0000FF,
        innocent: 0x00FF00,
        pending: 0x555555
      }[status]
    )
  end
end

class Discordrb::User
  def db_user
    User.find_by_discord_id self.id
  end
end

bot = Discordrb::Commands::CommandBot.new token: ENV['TRIAL_BOT_DISCORD_TOKEN'], application_id: ENV['TRIAL_BOT_DISCORD_APPID'], prefix: '!'

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
  unless message.author.db_user
    message.respond ":confused: You're not even logged in!"
    return
  end
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

bot.message(contains: /\A\d+\z/) do |message|
  message.channel.start_typing
  id = message.content.to_i

  message.channel.send_message '', false, Report.new(id).embed
end

bot.run
