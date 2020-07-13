namespace :push_line do 
  desc "天気の子" 
  task push_line_message: :environment do
    message = {
      type: 'text',
      text: '今から晴れるよ。'
    }
    client = Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
    response = client.push_message(ENV["LINE_CHANNEL_USER_ID"], message)
  end
end