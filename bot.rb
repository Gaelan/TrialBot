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

Bot = Discordrb::Commands::CommandBot.new token: ENV['TRIAL_BOT_DISCORD_TOKEN'], application_id: ENV['TRIAL_BOT_DISCORD_APPID'], prefix: '!'

FOOTERS = [
  "As a completely unbiased bot, I believe DoodleFungus would make an excellent judge.",
  "Reason: Gamethrowing. Details: None given.",
  "Reason: Gamethrowing. Details: throwing the game",
  "Dave has died. Dave was the Jailor. Dave has left the game.",
  "Beep boop.",
  "Don't lynch me, I'm baker!",
  "Bob was shot by a vigilante. Bob was a member of the Mafia. - No game, ever",
  "Oh, that's what the huge text box labeled 'Report Details' is for?",
  "Stupidity is still not reportable.",
  "Oh no, the game's getting DDOSed. What, I'm intentionally delaying the game? naaaah",
  "More like Town of Failum",
  "I am blackmailed.",
  "I a mblackmailed.",
  "Have an idea for the grey text? PM @Gaelan#0424"
]

def create_embed(options)
  options[:footer] ||= Discordrb::Webhooks::EmbedFooter.new(text: FOOTERS.sample)
  Discordrb::Webhooks::Embed.new(options)
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

Dir[File.dirname(__FILE__) + '/commands/*.rb'].each {|file| require file }

Bot.run
