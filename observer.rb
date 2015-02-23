require 'net/http'
require 'uri'
require 'tweetstream'
require 'parse-ruby-client'

Parse.init :application_id => ENV['PARSE_APP_ID'],
           :api_key        => ENV['PARSE_API_KEY']

TweetStream.configure do |config|
  config.consumer_key       = ENV['TWITTER_CONSUMER_KEY']
  config.consumer_secret    = ENV['TWITTER_CONSUMER_SECRET']
  config.oauth_token        = ENV['TWITTER_OAUTH_TOKEN']
  config.oauth_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET']
  config.auth_method        = :oauth
end

def push_notification(url) # must String
  data = { :alert => "Push from ruby sample!" + url.to_s, :url => url.to_s }
  push = Parse::Push.new(data)
  push.where = { :deviceType => "android" }
  p push.save
end

def replace_uri(s)
    str = s.dup
    uri_reg = URI.regexp(%w[http https])
    str.gsub!(uri_reg) {"#{$&}"}
    "#{$&}"
end

NOGIZAKA_BLOG = "http://blog.nogizaka46.com"

def expand_url(url)
  uri = url.kind_of?(URI) ? url : URI.parse(url)
  Net::HTTP.start(uri.host, uri.port) { |io|
    r = io.head(uri.path)
    r['Location'] || uri.to_s
  }
end

EM.run do
  client = TweetStream::Client.new
  # 1084091587 -> 練習用
  # 317684165 -> 本番
  client.follow(1084091587) do |status|
    puts "#{status.user.screen_name}: #{status.text}"

    url = replace_uri(status.text)
    if (!url.to_s.include?("http://t.co/") && !url.to_s.include?("http://bit.ly/"))
      puts "url may be not nogizaka blog domain : " + url.to_s
    else
      url = expand_url(url)
      if (url.include?(NOGIZAKA_BLOG))
        push_notification(url)
      else
        url = expand_url(url)
        if (url.include?(NOGIZAKA_BLOG))
          push_notification(url)
        else
          puts "url may be not nogizaka blog domain"
        end
      end
    end
  end

  client.on_error do |message|
    puts "error: #{message}\n"
  end

  client.on_reconnect do |timeout, retries|
    puts "reconnecting in: #{timeout} seconds\n"
  end

end
