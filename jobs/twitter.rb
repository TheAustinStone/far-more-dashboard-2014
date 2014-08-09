require "httparty"

SCHEDULER.every "15s", :first_in => 0 do |job|
  begin
    tweets = HTTParty.get("http://api.massrelevance.com/ElbenShira/far-more-2014.json")

    if tweets
      tweets = tweets.map do |tweet|
        ap tweet
        {
          name: tweet["user"]["name"],
          body: tweet["text"],
          avatar: tweet["user"]["profile_image_url_https"],
        }
      end

      send_event('twitter_mentions', comments: tweets)
    end
  end
end
