require 'bundler'
Bundler.setup
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

Bot =
  Discordrb::Commands::CommandBot.new token: ENV['TRIAL_BOT_DISCORD_TOKEN'],
                                      application_id:
                                        ENV['TRIAL_BOT_DISCORD_APPID'],
                                      prefix: '!'

def create_embed(options)
  Discordrb::Webhooks::Embed.new(options)
end

def api_call(options)
  agent = Mechanize.new
  page = agent.get('http://www.blankmediagames.com/phpbb/')
  page = page.links_with(text: 'Login')[0].click
  form = page.forms[]
  form.username = ENV['TOS_USERNAME']
  form.password = ENV['TOS_PASSWORD']
  page = agent.submit(form, form.buttons[0])
  JSON.parse(
    agent.get_file(
      "http://blankmediagames.com/Trial/api/api.php?#{options.to_a.map do |x|
        x.join '='
      end.join '&'}"
    )
  )
end

Dir[File.dirname(__FILE__) + '/commands/*.rb'].each { |file| require file }

Bot.run
