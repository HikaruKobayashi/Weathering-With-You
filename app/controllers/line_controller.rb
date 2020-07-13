class LineController < ApplicationController
  # モジュールを追加する。
  require 'line/bot'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'

  protect_from_forgery :except => [:callback]

  def client
    @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head :bad_request
    end

    events = client.parse_events_from(body)

    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Location
          # LINEの位置情報から緯度経度を取得する。
          latitude = event.message['latitude']
          longitude = event.message['longitude']
          appId = ENV["Whether_API_Key"]
          url= "http://api.openweathermap.org/data/2.5/forecast?lon=#{longitude}&lat=#{latitude}&APPID=#{appId}&units=metric&mode=xml"
         # XMLをパースする。
          xml  = open( url ).read.toutf8
          doc = REXML::Document.new(xml)
          xpath = 'weatherdata/forecast/time[1]/'
          nowWearther = doc.elements[xpath + 'symbol'].attributes['name']
          p nowWearther
          nowTemp = doc.elements[xpath + 'temperature'].attributes['value']
          p nowTemp
          case nowWearther
          # 条件が一致した場合、メッセージを返す処理。絵文字も入れています。
          when /.*(clear sky|few clouds).*/
            response = "送信された地点の天気は晴れです\u{2600}\n\n現在の気温は#{nowTemp}℃です\u{1F321} 「天気って不思議だ、ただの空模様に、こんなにも気持ちを動かされてしまう。心をひなさんに動かされてしまう。」"
          when /.*(scattered clouds|broken clouds|overcast clouds).*/
            response = "送信された地点の天気は曇りです\u{2601}\n\n現在の気温は#{nowTemp}℃です\u{1F321} 「天と地の間で振り落とされぬようしがみつき、ただ借り住まいさせていただいているのが人間。」"
          when /.*(rain|thunderstorm|drizzle).*/
            response = "送信された地点の天気は雨です\u{2614}\n\n現在の気温は#{nowTemp}℃です\u{1F321} 「おい。まぁ気にすんなよ青年。世界なんてさ、どうせもともと狂ってんだから。」"
          when /.*(snow).*/
            response = "送信された地点の天気は雪です\u{2744}\n\n現在の気温は#{nowTemp}℃です\u{1F321} 「神様、お願いです。これ以上僕たちになにも足さず、僕たちからなにも引かないでください。」"
          when /.*(fog|mist|Haze).*/
            response = "送信された地点では霧が発生しています\u{1F32B}\n\n現在の気温は#{nowTemp}℃です\u{1F321} 「あの空の上で僕たちは、世界の形を変えてしまったんだ。」"
          else
            response = "送信された地点では何かが発生していますが、\nご自身でお確かめください。\u{1F605}\n\n現在の気温は#{nowTemp}℃です\u{1F321} 「天気なんて、狂ったままでいいんだ！」"
          end
          # オブジェクトを作成する。
          message = {
            type: 'text',
            text: response
          }
          client.reply_message(event['replyToken'], message) # 返信する。
        end
      end
    }

    head :ok
  end
end