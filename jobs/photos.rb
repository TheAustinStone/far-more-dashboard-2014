require 'awesome_print'
require 'httparty'
require 'json'

FLICKR_URL_BASE = "https://api.flickr.com/services/rest"
FLICKR_KEY = ENV["FLICKR_KEY"]
MAX_PHOTOS = 10

# lots of variants for the likely case that someone forgets to use the right tag
PHOTO_TAGS = [
  "farmore",
  "far-more",
  "farmore2014",
  "farmore-2014",
  "far-more2014",
  "far-more-2014",
]

SCHEDULER.every '3m', :first_in => 0 do
  # get recent Flickr photos from tagged with `farmore`
  resp = HTTParty.get(FLICKR_URL_BASE, query: {
    # boilerplate
    method: "flickr.photos.search",
    api_key: FLICKR_KEY,
    format: "json",
    nojsoncallback: 1,

    per_page: MAX_PHOTOS,
    media: 'photos',

    # find photos from the Stone tagged with any variant of 'farmore'
    user_id: "theaustinstone",
    tags: PHOTO_TAGS.join(","),
  })

  # get direct URLs to each photo in the response
  photo_urls = resp["photos"]["photo"].map do |p|
    # build a photo URL as described at:
    # http://www.herongyang.com/Free-Web-Service/Flickr-Construct-Image-Source-URL-on-Flickr.html
    # otherwise, we'd need to make a request per photo, which is both slow _and_
    # a lot of requests for such a simple thing.
    "http://farm#{p["farm"]}.static.flickr.com/#{p["server"]}/#{p["id"]}_#{p["secret"]}.jpg"
  end

  send_event('farmore-photos', urls: photo_urls)
end
