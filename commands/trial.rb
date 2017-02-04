require_relative 'accounts'

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
    create_embed(
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

Bot.command :reports do |message, *opts|
  channel = if opts.include? 'public'
    message.channel
  else
    message.author.pm
  end
  authenticate(message) do |user|
    action = (opts.include? 'all') ? 'getallreports' : 'getreports'
    reports = api_call action: action, user: user.tos_name
    message.respond ':arrow_right: Report information sent via PM.' unless opts.include? 'public'
    if reports['ErrorMessage'] && reports['ErrorMessage'] =~ /no guilty reports/
      channel.send_message ":star2: #{reports['ErrorMessage']}"
    elsif reports['ErrorMessage'] != ''
      channel.send_message ":x: #{reports['ErrorMessage']}"
    else
      channel.send_message ":frowning: You have #{reports['ReportID'].length} guilty reports:"
      reports['ReportID'].each do |id|
        channel.send_embed '', Report.new(id).embed
      end
    end
    return
  end
end

Bot.command :report do |message, id_string|
  id = id_string.to_i
  message.channel.send_message '', false, Report.new(id).embed
end

Bot.message(contains: /\A\d+\z/) do |message|
  if message.channel.config.short_reports?
    message.channel.start_typing
    id = message.content.to_i

    message.channel.send_message '', false, Report.new(id).embed
  end
end